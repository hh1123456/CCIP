// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console2} from "../forge-std/src/Test.sol";
import {CCIPSender_Unsafe} from "../src/test/CCIPSender_Unsafe.sol";
import {CCIPReceiver_Unsafe} from "../src/test/CCIPReceiver_Unsafe.sol";
import {CCIPLocalSimulator, IRouterClient, LinkToken, BurnMintERC677Helper, WETH9} from "../src/ccip/CCIPLocalSimulator.sol";

contract UnsafeTokenAndDataTransferTest is Test {
    CCIPSender_Unsafe public sender;
    CCIPReceiver_Unsafe public receiver;

    uint64 chainSelector;
    BurnMintERC677Helper ccipBnM;

  function setUp() public {
    // 创建本地模拟器
    CCIPLocalSimulator ccipLocalSimulator = new CCIPLocalSimulator();

    // 获取模拟器的配置，注意现在有7个返回值
    (
        uint64 chainSelector_,
        IRouterClient sourceRouter_,
        IRouterClient destinationRouter_,
        WETH9 wrappedNative_,
        LinkToken linkToken_,
        BurnMintERC677Helper ccipBnM_,
        BurnMintERC677Helper ccipLnM_
    ) = ccipLocalSimulator.configuration();

    // 初始化变量
    chainSelector = chainSelector_;
    ccipBnM = ccipBnM_;
    
    // 如果需要使用 wrappedNative_ 和 ccipLnM_，可以在这里处理
    // 例如：
     WETH9 wrappedNative = wrappedNative_;
     BurnMintERC677Helper ccipLnM = ccipLnM_;

    address sourceRouter = address(sourceRouter_);
    address linkToken = address(linkToken_);
    address destinationRouter = address(destinationRouter_);

    // 创建 CCIP 发送方和接收方
    sender = new CCIPSender_Unsafe(linkToken, sourceRouter);
    receiver = new CCIPReceiver_Unsafe(destinationRouter);
}


    function testSend() public {
        ccipBnM.drip(address(sender)); // 1e18
        assertEq(ccipBnM.totalSupply(), 1 ether);

        string memory textToSend = "Hello World";
        uint256 amountToSend = 100;

        bytes32 messageId = sender.send(
            address(receiver),
            textToSend,
            chainSelector,
            address(ccipBnM),
            amountToSend
        );
        console2.logBytes32(messageId);

        string memory receivedText = receiver.text();

        assertEq(receivedText, textToSend);

        assertEq(ccipBnM.balanceOf(address(sender)), 1 ether - amountToSend);
        assertEq(ccipBnM.balanceOf(address(receiver)), amountToSend);
        assertEq(ccipBnM.totalSupply(), 1 ether);
    }
}
