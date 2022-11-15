// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

/**
 * @notice a base contract for logic extensions that use the diamond pattern storage
 * to map the functions when looking up the extension contract to delegate to.
 */
abstract contract DiamondExtension {
  /**
   * @return a list of all the function selectors that this logic extension exposes
   */
  function _getExtensionFunctions() external view virtual returns (bytes4[] memory);
}

abstract contract DiamondBase {
  /**
   * @dev register a logic extension
   * @param extensionToAdd the extension whose functions are to be added
   * @param extensionToReplace the extension whose functions are to be removed/replaced
   */
  function _registerExtension(DiamondExtension extensionToAdd, DiamondExtension extensionToReplace) external virtual;

  fallback() external payable {
    address extension = LibDiamond.getExtensionForFunction(msg.sig);
    // Execute external function from extension using delegatecall and return any value.
    assembly {
      // copy function selector and any arguments
      calldatacopy(0, 0, calldatasize())
      // execute function call using the extension
      let result := delegatecall(gas(), extension, 0, calldatasize(), 0, 0)
      // get any return value
      returndatacopy(0, 0, returndatasize())
      // return any return value or error back to the caller
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }
}

/**
 * @notice a library to use in a contract, whose logic is extended with diamond extension
 */
library LibDiamond {
  bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

  struct Function {
    address implementation;
    uint16 index; // used to remove functions without looping
  }

  struct LogicStorage {
    mapping(bytes4 => Function) functions;
    bytes4[] selectorAtIndex;
    // mapping(bytes4 => bool) supportedInterfaces;
  }

  function getExtensionForFunction(bytes4 msgSig) internal view returns (address) {
    LibDiamond.LogicStorage storage ds = diamondStorage();
    address extension = ds.functions[msgSig].implementation;
    require(extension != address(0), "Diamond: Function does not exist");
    return extension;
  }

  function diamondStorage() internal pure returns (LogicStorage storage ds) {
    bytes32 position = DIAMOND_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function registerExtension(DiamondExtension extensionToAdd, DiamondExtension extensionToReplace) internal {
    if (address(extensionToReplace) != address(0)) {
      // remove all functions of the extension to replace
      removeExtensionFunctions(extensionToReplace);
    }

    addExtensionFunctions(extensionToAdd);
  }

  function removeExtensionFunctions(DiamondExtension extension) internal {
    bytes4[] memory fnsToRemove = extension._getExtensionFunctions();
    LogicStorage storage ds = diamondStorage();
    for (uint16 i = 0; i < fnsToRemove.length; i++) {
      bytes4 selectorToRemove = fnsToRemove[i];
      //address selectorImpl = ds.functions[selector].implementation;
      //if (selectorImpl == extension)
      {
        // swap with the last element in the selectorAtIndex array and remove the last element
        uint16 indexToKeep = ds.functions[selectorToRemove].index;
        ds.selectorAtIndex[indexToKeep] = ds.selectorAtIndex[ds.selectorAtIndex.length - 1];
        ds.functions[ds.selectorAtIndex[indexToKeep]].index = indexToKeep;
        ds.selectorAtIndex.pop();
        delete ds.functions[selectorToRemove];
      }
    }
  }

  function addExtensionFunctions(DiamondExtension extension) internal {
    bytes4[] memory fnsToAdd = extension._getExtensionFunctions();
    LogicStorage storage ds = diamondStorage();
    uint16 selectorCount = uint16(ds.selectorAtIndex.length);
    for (uint256 selectorIndex; selectorIndex < fnsToAdd.length; selectorIndex++) {
      bytes4 selector = fnsToAdd[selectorIndex];
      address oldImplementation = ds.functions[selector].implementation;
      require(oldImplementation == address(0), "CannotAddFunctionToDiamondThatAlreadyExists");
      ds.functions[selector] = Function(address(extension), selectorCount);
      ds.selectorAtIndex.push(selector);
      selectorCount++;
    }
  }
}
