// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title Domino Token - Cross-Chain Rebase Token
 * @author dumebai
 *
 * @notice This is a cross-chain rebase token implementation that incentivizes
 * users to deposit into a vault and gain interest in reward.
 * @notice The interest rate in the smart contract can only decrease.
 * @notice Each user will have their own interest rate, that is the global
 * interest rate at the time of deposit.
 *
 */
contract DominoToken is ERC20, Ownable, AccessControl {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error DominoToken__InterestRateCanOnlyDecrease();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    uint256 private s_interestRate = 5e10; // working in 18 decimal precision
    uint256 private constant PRECISION_FACTOR = 1e18;
    bytes32 private constant MINT_AND_BURN_ROLE = keccak256("MINT_AND_BURN_ROLE"); // hashing the string to get the bytes32 constant

    mapping(address => uint256) private s_userInterestRate;
    mapping(address => uint256) private s_userLastUpdatedTimestamp;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event InterestRateSet(uint256 interestRate);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() ERC20("Domino Token", "DOMINO") Ownable(msg.sender) {}

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function grantMintAndBurnRole(address _account) external onlyOwner {
        _grantRole(MINT_AND_BURN_ROLE, _account);
    }

    /**
     * @notice Set the interest rate in the contract
     * @param _newInterestRate - The new interest rate to set.
     * @dev The interest rate can only decrease.
     */
    function setInterestRate(uint256 _newInterestRate) external onlyOwner {
        if (_newInterestRate > s_interestRate) {
            revert DominoToken__InterestRateCanOnlyDecrease();
        }
        // Set the interest rate
        s_interestRate = _newInterestRate;
        emit InterestRateSet(_newInterestRate);
    }

    /**
     * @notice Mint the user token when they deposit into the vault.
     * @param _to - The user to mint the tokens to.
     * @param _amount - The amount of tokens to mint.
     * @dev The interest rate is associated with the user using s_userInterestRate.
     */
    function mint(address _to, uint256 _amount) external onlyRole(MINT_AND_BURN_ROLE) {
        _mintAccruedInterest(_to);
        s_userInterestRate[_to] = s_interestRate;
        _mint(_to, _amount);
    }

    /**
     * @notice Burn the user tokens when they withdraw from the vault.
     * @notice _mintAccruedInterest before burning.
     * @param _from - The user to burn the tokens from.
     * @param _amount - The amount of tokens to burn.
     *
     * NOTE: @notice needs to be updated when other burn mechanism is implemented.
     */
    function burn(address _from, uint256 _amount) external onlyRole(MINT_AND_BURN_ROLE) {
        // Mitigate against dust.
        if (_amount == type(uint256).max) {
            _amount = balanceOf(_from);
        }
        _mintAccruedInterest(_from);
        _burn(_from, _amount);
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Transfer tokens to a user.
     * @param _recipient - The user to transfer the tokens to.
     * @param _amount - The amount of tokens to transfer.
     * @return True if the transfer was successful.
     */
    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_userInterestRate[msg.sender];
        }
        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(_recipient);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(msg.sender);
        }
        return super.transfer(_recipient, _amount);
    }

    /**
     * @notice Transfer tokens from one user to another.
     * @param _sender - The user to transfer the tokens from.
     * @param _recipient - The user to transfer the tokens to.
     * @param _amount - The amount of tokens to transfer.
     * @return True if the transfer was successful.
     */
    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_userInterestRate[_sender];
        }
        _mintAccruedInterest(_sender);
        _mintAccruedInterest(_recipient);

        if (_amount == type(uint256).max) {
            _amount = balanceOf(_sender);
        }

        return super.transferFrom(_sender, _recipient, _amount);
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Mint the accrued interest to the user since the last time they
     * interacted with the protocol (e.g. burn, mint, transfer)
     * @param _user - The user to mint the accrued interest to.
     */
    function _mintAccruedInterest(address _user) internal {
        // (1) Find the current balance of rebase tokens that have been minted to the user -> principal balance.
        uint256 previousPrincipalBalance = super.balanceOf(_user);
        // (2) Calculate their ballance including any interest -> returned from balanceOf
        uint256 currentBalance = balanceOf(_user);
        // Calculate the number of token that need to be minted to the user (2) - (1).
        uint256 balanceIncrease = currentBalance - previousPrincipalBalance;
        // Set the user last updated timestamp.
        s_userLastUpdatedTimestamp[_user] = block.timestamp;
        // Call _mint to mint the tokens to the user.
        _mint(_user, balanceIncrease);
        // Already emitting event in _mint function.
    }

    /**
     * @notice Calculate the interest that has accumulated since the last update.
     * @param _user - The user to calculate the interest accumulated for.
     * @return linearInterest - The interest that has accumulated since the last update.
     */
    function _calculateUserAccumulatedInterestSinceLastUpdate(address _user)
        internal
        view
        returns (uint256 linearInterest)
    {
        // Calculate the interest that has accumulated since the last update.
        // Linear growth with time.

        // 1. Calculate the time since the last update.
        uint256 timeElapsed = block.timestamp - s_userLastUpdatedTimestamp[_user];
        // 2. Calculate the amount of linear growth.
        // principal amount(1 + (user interest rate * time elapsed))
        // deposit: 10 tokens
        // interest rate 0.5 tokens per second
        // time elapsed is 2 seconds
        linearInterest = PRECISION_FACTOR + (s_userInterestRate[_user] * timeElapsed);
    }

    /*//////////////////////////////////////////////////////////////
                         VIEW & PURE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get the principal balance of a user.
     * This is the number of tokens that have currently been minted to the user,
     * not including any interest that has accrued since the last time the user
     * has interacted with the protocol.
     * @param _user The user to get the principal balance for.
     * @return The principal balance of the user.
     */
    function principalBalanceOf(address _user) external view returns (uint256) {
        return super.balanceOf(_user);
    }

    /**
     * @notice Calculate the balance for the user including the interest that
     * has accumulated since the last update.
     * (principal balance) + some interest that has accrued.
     * @param _user The user to calculate the balance for.
     * @return The balance of the user including the interest that has
     * accumulated since the last update.
     */
    function balanceOf(address _user) public view override returns (uint256) {
        // Get the current principal balance of the user
        // The number of tokens that have actually been minted to the user.
        // Multiply the principal balance by the interest that has accumulated
        // in the time since the balance was last updated.
        return super.balanceOf(_user) * _calculateUserAccumulatedInterestSinceLastUpdate(_user) / PRECISION_FACTOR;
    }

    function getInterestRate() external view returns (uint256) {
        return s_interestRate;
    }

    function getUserInterestRate(address _user) external view returns (uint256) {
        return s_userInterestRate[_user];
    }
}
