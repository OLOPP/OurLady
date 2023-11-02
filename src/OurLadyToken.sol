/*
  _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _  
{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}
 /_\  /_\  /_\  /_\  /_\  /_\  /_\  /_\  /_\  /_\  /_\  /_\  /_\  /_\  /_\  /_\  /_\  /_\  /_\  /_\  /_\  /_\  /_\ 
  _            ....                                           ...                     ..                        _  
{\o/}      .x~X88888Hx.                                   .zf"` `"tu                dF           ..           {\o/}
 /_\      H8X 888888888h.      x.    .        .u    .    x88      '8N.             '88bu.       @L             /_\ 
  _      8888:`*888888888:   .@88k  z88u    .d88B :@8c   888k     d88&       u     '*88888bu   9888i   .dL      _  
{\o/}    88888:        `%8  ~"8888 ^8888   ="8888f8888r  8888N.  @888F    us888u.    ^"*8888N  `Y888k:*888.   {\o/}
 /_\   . `88888          ?>   8888  888R     4888>'88"   `88888 9888%  .@88 "8888"  beWE "888L   888E  888I    /_\ 
  _    `. ?888%           X   8888  888R     4888> '       %888 "88F   9888  9888   888E  888E   888E  888I     _  
{\o/}    ~*??.            >   8888  888R     4888>          8"   "*h=~ 9888  9888   888E  888E   888E  888I   {\o/}
 /_\    .x88888h.        <    8888 ,888B .  .d888L .+     z8Weu        9888  9888   888E  888F   888E  888I    /_\ 
  _    :"""8888888x..  .x    "8888Y 8888"   ^"8888*"     ""88888i.   Z 9888  9888  .888N..888   x888N><888'     _  
{\o/}  `    `*888888888"      `Y"   'YP        "Y"      "   "8888888*  "888*""888"  `"888*""     "88"  888    {\o/}
 /_\           ""***""                                        ^"**""    ^Y"   ^Y'      ""              88F     /_\ 
  _                                                                                                   98"       _  
{\o/}                                                                                               ./"       {\o/}
 /_\                                                                                               ~`          /_\ 
  _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _    _  
{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}{\o/}
 /_\  /_\  /_\  /_\  /_\  /_\  /_\  /_\  /_\  /_\  /_\  /_\  /_\  /_\  /_\  /_\  /_\  /_\  /_\  /_\  /_\  /_\  /_\ 

 Our Lady of Perpetual Profit -> www.ourlady.io |  x.com/ourladytoken | https://t.me/ourladytoken 

 */

 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract OurLady is VRFConsumerBaseV2 {
  
  uint public lotteryId;
  mapping (uint => address payable) public lotteryHistory;



}


 