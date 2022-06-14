// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IUniswapV2Router {

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract MultiPaymentContractV2 is Ownable {

    IUniswapV2Router public immutable router;
    IERC20 public immutable PKN;

    address public feeRecipient;

    uint256 public feePercent;

    constructor(
        IERC20 _pkn,
        IUniswapV2Router _router,
        address _feeRecipient,
        uint256 _feePercent
    ) {
        PKN = _pkn;
        router = _router;

        feeRecipient = _feeRecipient;
        feePercent = _feePercent;
    }

    function payETH(
        address seller,
        address[] calldata creators,
        uint256[] calldata royaltyPercents,
        uint256 minPKNOut
    ) external payable {

        uint256 length = creators.length;
        require(length == royaltyPercents.length, "Input length mismatch");

        uint256 balanceBefore = PKN.balanceOf(address(this));
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(PKN);
        
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            minPKNOut,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = PKN.balanceOf(address(this)) - balanceBefore;

        uint256 creatorShare;
        for(uint256 i = 0; i < length; i++) {
            uint256 share = amount * royaltyPercents[i] / 10000;
            creatorShare += share;
            PKN.transfer(creators[i], share);
        }

        uint256 platformShare = amount * feePercent / 10000;
        PKN.transfer(feeRecipient, platformShare);
        PKN.transfer(seller, amount - creatorShare - platformShare);
    }

    function payERC20(
        address seller,
        address[] calldata creators,
        uint256[] calldata royaltyPercents,
        address[] calldata path,
        uint256 amountIn,
        uint256 minPKNOut
    ) external {

        uint256 length = creators.length;
        require(length == royaltyPercents.length, "Input length mismatch");

        uint256 balanceBefore = PKN.balanceOf(address(this));

        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        IERC20(path[0]).approve(address(router), amountIn);

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            minPKNOut,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = PKN.balanceOf(address(this)) - balanceBefore;

        uint256 creatorShare;
        for(uint256 i = 0; i < length; i++) {
            uint256 share = amount * royaltyPercents[i] / 10000;
            creatorShare += share;
            PKN.transfer(creators[i], share);
        }

        uint256 platformShare = amount * feePercent / 10000;
        PKN.transfer(feeRecipient, platformShare);
        PKN.transfer(seller, amount - creatorShare - platformShare);
    }

    function changeFeeRecipient(address _feeRecipient) external onlyOwner {
        feeRecipient = _feeRecipient;
    }

    function changeFeePercent(uint256 _feePercent) external onlyOwner {
        feePercent = _feePercent;
    }
}
