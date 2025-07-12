// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {IDominoToken} from "./interfaces/IDominoToken.sol";

/**
 * @title Domino Vault - Cross-Chain Rebase Token Vault
 * @author dumebai
 *
 * @notice This is a vault implementation that incentivizes
 * users to deposit into a vault and gain interest in reward.
 */
contract DominoVault {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error DominoVault__RedeemFailed();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    IDominoToken private immutable i_token;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    // Indexed address so deposit events can be filtered by address
    event Deposit(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(IDominoToken _token) {
        // Pass the token address to the constructor.
        i_token = _token;
    }

    /*//////////////////////////////////////////////////////////////
                            RECEIVE FUNCTION
    //////////////////////////////////////////////////////////////*/
    receive() external payable {}

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Allows users to deposit ETH into the vault and mint
     * equal amount of DOMINO in return.
     */
    function deposit() external payable {
        // Use the amount of ETH the user has sent to mint tokens to the user.
        i_token.mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @notice Allows users to redeem their DOMINO tokens for ETH.
     * @notice Function burns from the user and sends ETH.
     * @param _amount - The amount of DOMINO tokens to redeem.
     */
    function redeem(uint256 _amount) external {
        // 1. Burn the tokens from the user.
        i_token.burn(msg.sender, _amount);
        // 2. Sent the user ETH.
        // payable(msg.sender).transfer(_amount); - not a best practice.
        (bool success,) = payable(msg.sender).call{value: _amount}("");
        if (!success) {
            revert DominoVault__RedeemFailed();
        }
        emit Redeem(msg.sender, _amount);
    }
    // Create a way to add rewards to the vault.

    /*//////////////////////////////////////////////////////////////
                         VIEW & PURE FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    function getTokenAddress() external view returns (address) {
        return address(i_token);
    }
}
