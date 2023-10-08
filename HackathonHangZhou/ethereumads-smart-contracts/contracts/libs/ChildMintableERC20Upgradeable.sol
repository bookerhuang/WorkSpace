// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

import {AccessControlMixin} from "./AccessControlMixin.sol";
import {IChildToken} from "./IChildToken.sol";
import {NativeMetaTransaction} from "./NativeMetaTransaction.sol";
import {ContextMixin} from "./ContextMixin.sol";


contract ChildMintableERC20Upgradeable is
    Initializable,
    ERC20Upgradeable,
    IChildToken,
    AccessControlMixin,
    NativeMetaTransaction,
    ContextMixin
{
    bytes32 public constant DEPOSITOR_ROLE = keccak256("DEPOSITOR_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        address childChainManager
    ) public initializer {
        __ERC20_init(name_, symbol_);
        _setupContractId("ChildMintableERC20");
        _setupDecimals(decimals_);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(DEPOSITOR_ROLE, childChainManager);
        _initializeEIP712(name_,"1");
    }

    // This is to support Native meta transactions
    // never use msg.sender directly, use _msgSender() instead
    function _msgSender()
        internal
        override
        view
        returns (address payable sender)
    {
        return ContextMixin.msgSender();
    }

    /**
     * @notice called when token is deposited on root chain
     * @dev Should be callable only by ChildChainManager
     * Should handle deposit by minting the required amount for user
     * Make sure minting is done only by this function
     * @param user user address for whom deposit is being done
     * @param depositData abi encoded amount
     */
    function deposit(address user, bytes calldata depositData)
        external
        override
        only(DEPOSITOR_ROLE)
    {
        uint256 amount = abi.decode(depositData, (uint256));
        _mint(user, amount);
    }

    /**
     * @notice called when user wants to withdraw tokens back to root chain
     * @dev Should burn user's tokens. This transaction will be verified when exiting on root chain
     * @param amount amount of tokens to withdraw
     */
    function withdraw(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    /**
     * @notice Example function to handle minting tokens on matic chain
     * @dev Minting can be done as per requirement,
     * @param user user for whom tokens are being minted
     * @param amount amount of token to mint
     */
    function mint(address user, uint256 amount) public only(MINTER_ROLE) {
        _mint(user, amount);
    }
}
