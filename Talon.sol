pragma solidity ^0.4.9;

import "./ERC223_Interface.sol";
import "./Upgradable.sol";

contract ContractReceiver { function tokenFallback(address _from, uint _value, bytes _data); }
 
 /* https://github.com/LykkeCity/EthereumApiDotNetCore/blob/master/src/ContractBuilder/contracts/token/SafeMath.sol */
contract SafeMath {
    uint256 constant MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (x > MAX_UINT256 - y) throw;
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (x < y) throw;
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        if (y == 0) return 0;
        if (x > MAX_UINT256 / y) throw;
        return x * y;
    }
}
 
contract Talon is ERC223, SafeMath, Upgradable {
    
    event Reward(address indexed _miner, uint256 _value, bool _current);

  mapping(address => uint) balances;
  
  string public name = "Talon-TEST";
  string public symbol = "TLN";
  uint8 public decimals = 18;
  uint256 public totalSupply;
  
  uint public miningStartBlock;
  uint public targetSupply = 40000000 * (10**18);
  
  // 1 block = 15 seconds
  // emission rate = 4 blocks/minute
  // 4 * 60 * 24 * 365 * 4 = 8409600 blocks for 4 years.
  uint public miningEndBlock = miningStartBlock + 8409600;
  uint public lastMinedBlock;
  uint public rewardClaimDelay = 5; // 5 blocks delay between reward claims.
  
  // Debug variables.
  address public owner;
  bool public debug = true;
  
  modifier onlyowner() {
      if(msg.sender!=owner) {
          throw;
      }
      _;
  }
  
  modifier onlydebug() {
      if(!debug) {
          throw;
      }
      _;
  }
  
  
  // Function to access name of token .
  function name() constant returns (string _name) {
      return name;
  }
  // Function to access symbol of token .
  function symbol() constant returns (string _symbol) {
      return symbol;
  }
  // Function to access decimals of token .
  function decimals() constant returns (uint8 _decimals) {
      return decimals;
  }
  // Function to access total supply of tokens .
  function totalSupply() constant returns (uint256 _totalSupply) {
      return totalSupply;
  }
  // Function to access the last block, when a reward for mining can be claimed.
  function miningEndBlock() constant returns (uint256 _miningEndBlock) {
      return miningEndBlock;
  }
  // Function to access the last block, which was declared a block when mining reward was claimed .
  function lastMinedBlock() constant returns (uint256 _lastMinedBlock) {
      return lastMinedBlock;
  }
  
  
  function Talon() {
      // 2 216 000 TLN for crowdsales etc. etc.
      balances[msg.sender] = 22160000 * (10**18);
      totalSupply = balances[msg.sender];
      miningStartBlock = block.number;
      lastMinedBlock = miningStartBlock;
      miningEndBlock = miningStartBlock + 8409600;
      owner = msg.sender;
  }
  

  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data) deprecatable returns (bool success) {
      
    if(isContract(_to)) {
        transferToContract(_to, _value, _data);
    }
    else {
        transferToAddress(_to, _value, _data);
    }
    return true;
}
  
  // Standard function transfer similar to ERC20 transfer with no _data .
  // Added due to backwards compatibility reasons .
  function transfer(address _to, uint _value) deprecatable returns (bool success) {
      
    //standard function transfer similar to ERC20 transfer with no _data
    //added due to backwards compatibility reasons
    bytes memory _empty;
    if(isContract(_to)) {
        transferToContract(_to, _value, _empty);
    }
    else {
        transferToAddress(_to, _value, _empty);
    }
    return true;
}

//assemble the given address bytecode. If bytecode exists then the _addr is a contract.
  function isContract(address _addr) private returns (bool is_contract) {
      uint length;
      assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        if(length>0) {
            return true;
        }
        else {
            return false;
        }
    }

  //function that is called when transaction target is an address
  function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) throw;
    balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
    balances[_to] = safeAdd(balanceOf(_to), _value);
    Transfer(msg.sender, _to, _value, _data);
    return true;
  }
  
  //function that is called when transaction target is a contract
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    if (balanceOf(msg.sender) < _value) throw;
    balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
    balances[_to] = safeAdd(balanceOf(_to), _value);
    ContractReceiver reciever = ContractReceiver(_to);
    reciever.tokenFallback(msg.sender, _value, _data);
    Transfer(msg.sender, _to, _value, _data);
    return true;
}


  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
  
  function nextReward() constant returns (uint256 _blockNumber) {
      return lastMinedBlock + rewardClaimDelay;
  }
  
  function avgBlockReward() constant returns (uint256 _reward) {
      if(totalSupply >= targetSupply) throw;
      
      if(block.number <= miningEndBlock) {
            return (targetSupply - totalSupply)/(miningEndBlock - block.number);
      }
      return 0;
  }
  
  function claim() deprecatable {
    if (block.number < nextReward()) {
        throw;
    }
    else {
        uint reward = (block.number - lastMinedBlock) * avgBlockReward();
    }
    if (reward > 0) {
        balances[block.coinbase] += reward;
        totalSupply += reward;
        lastMinedBlock = block.number;
        Reward(block.coinbase, reward, true);
    }
  }
  
  
  
  // Debug functions.
  
  function updateBalance(address _addr) {
      Talon tln = Talon(destination);
      tln.receiveUpdate(_addr, balances[_addr]);
  }
  
  function deprecate(address _destination) onlyowner deprecatable {
      destination = _destination;
      deprecated = true;
  }
  
  function setPrevious(address _previousContract) onlyowner {
      previousContract = _previousContract;
  }
  
  function receiveUpdate(address _addr, uint256 _balance) {
      if(msg.sender != previousContract) throw;
      
      balances[_addr] = _balance;
  }
    
    function DEBUG_targetSupply(uint _targetSupply) onlyowner onlydebug {
        targetSupply = _targetSupply;
    }
    
    function DEBUG_miningEndBlock(uint _miningEndBlock) onlyowner onlydebug {
        miningEndBlock = _miningEndBlock;
    }
    
    function DEBUG_rewardClaimDelay(uint _rewardClaimDelay) onlyowner onlydebug {
        rewardClaimDelay = _rewardClaimDelay;
    }
    
    function DEBUG_transferOwnership(address _newOwner) onlyowner onlydebug {
        owner = _newOwner;
    }
    
    function DEBUG_turnOffDebug() onlyowner onlydebug {
        debug = false;
    }
}
