pragma solidity ^0.4.9;


contract Upgradable {
  bool public deprecated = false;
  address public destination;
  address public previousContract;
  
  modifier deprecatable() {
      if(deprecated) {
          throw;
      }
      _;
  }
  
  function deprecate(address _destination) {
      destination = _destination;
      deprecated = true;
  }
  
  function setPrevious(address _previousContract) {
      previousContract = _previousContract;
  }
}
