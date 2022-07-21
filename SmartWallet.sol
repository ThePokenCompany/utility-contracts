// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

contract Wallet is Initializable {

    bytes4 internal constant _INTERFACE_ID_ERC1271 = 0x1626ba7e;
    bytes4 internal constant _ERC1271FAILVALUE = 0xffffffff;

    address public owner;

    mapping(bytes => uint256) internal _signatureExpiry;

    event Invoked(address indexed module, address indexed target, uint256 indexed value, bytes data);

    function initialize(address _owner) initializer() external {
        owner = _owner;
    }

    function isValidSignature(bytes32, bytes memory signature) external view returns (bytes4) {
        if(block.timestamp <= _signatureExpiry[signature]) {
            return _INTERFACE_ID_ERC1271;
        }
        return _ERC1271FAILVALUE;
    }

    function addSignature(bytes memory signature, uint256 deadline) external {
        require(msg.sender == address(this), "NOT_AUTHORIZED");
        _signatureExpiry[signature] = deadline;
    }

    function updateOwner(address _newOwner) external {
        require(msg.sender == address(this), "NOT_AUTHORIZED");
        owner = _newOwner;
    }

    function invoke(address _target, uint256 _value, bytes calldata _data) external returns (bytes memory _result) {
        require(owner == msg.sender, "NOT_AUTHORIZED");

        bool success;
        (success, _result) = _target.call{value: _value}(_data);
        if (!success) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }

        emit Invoked(msg.sender, _target, _value, _data);
    }

    receive() external payable {}
}

contract WalletFactory is AccessControl {

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    event WalletCreated(address wallet);

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
    }
    
    function computeAddress(bytes32 salt) public view returns (address) {
        return Create2.computeAddress(salt, keccak256(type(Wallet).creationCode));
    }

    function isWalletDeployed(bytes32 salt) public view returns (bool) {
        address wallet = Create2.computeAddress(salt, keccak256(type(Wallet).creationCode));
        return wallet.code.length > 0;
    }

    function deployWallet(bytes32 salt) external onlyRole(OPERATOR_ROLE) {
        address payable walletAddress = payable(Create2.deploy(0, salt, type(Wallet).creationCode));
        Wallet(walletAddress).initialize(address(this));
        emit WalletCreated(walletAddress);
    }
    
    /**
     * @notice Performs a generic transaction.
     * @param salt The salt for the wallet
     * @param target The address for the transaction.
     * @param value The value of the transaction.
     * @param data The data of the transaction.
     */
    function invoke(bytes32 salt, address target, uint256 value, bytes calldata data) external  onlyRole(OPERATOR_ROLE) {
        address walletAddress = computeAddress(salt);
        Wallet(payable(walletAddress)).invoke( target, value, data); 
    }

    function invokeBatch(bytes32 salt, address[] calldata targets, uint256[] calldata values, bytes[] calldata allData) external  onlyRole(OPERATOR_ROLE) {
        address payable walletAddress = payable(computeAddress(salt));

        uint256 len1 = targets.length;
        uint256 len2 = values.length;
        uint256 len3 = allData.length;

        require(len1 == len2 && len2 == len3, "INPUT_LENGTH_MISMATCH");

        for(uint256 i = 0; i < len1; i++) {
            Wallet(walletAddress).invoke(targets[i], values[i], allData[i]);
        }
    }
}
