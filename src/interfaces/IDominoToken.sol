// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

/**
 * @title IDominoToken Interface
 * @author dumebai
 *
 * @notice This is an interface implementation used in DominoVault.sol
 * @dev IDominoToken private immutable i_token and then cast as needed.
 */
interface IDominoToken {
    function mint(address _to, uint256 _amount) external;
    function burn(address from, uint256 _amount) external;
}
