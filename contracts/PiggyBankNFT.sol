// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./PiggyToken.sol";

/**
@title PiggyBankNFT
@dev This contract is an ERC721 compliant contract that represents a PiggyBank. 
It allows users to lock their tokens for a specific period of time and receive a bonus as a reward. 
The contract also allows users to mint PiggyBankNFT tokens of different tiers, 
each with a specific locking period and bonus percentage.
*/

contract PiggyBankNFT is ERC721, Ownable, ERC721Burnable, ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct PiggyBankTier {
        uint lockingPeriod;
        uint bonusPercentage;
    }

    struct Lock {
        address user;
        uint amount;
        uint lockingPeriod;
        uint bonusPercentage;
        uint startTime;
        bool isCompleted;
    }

    PiggyToken public token;

    mapping(uint => PiggyBankTier) public tiers;
    mapping(uint => Lock) public locks;
    mapping(uint => uint) public tokenIdTotierId;
    mapping(address => mapping(uint => bool)) public isActive;

    event PiggyBankNFTCreated(address owner, uint tokenId, uint tierId);
    event TokensLocked(
        address user,
        uint amount,
        uint lockingPeriod,
        uint bonusPercentage
    );
    event NFTCashedOut(uint tokenId, address user, uint amount);

    /**
 * @dev Constructor that sets the PiggyToken contract address and 
 initializes the ERC721 contract with the name "PiggyBankNFT" and symbol "PB".
 * @param _token The address of the PiggyToken contract.
 */
    constructor(address _token) ERC721("PiggyBankNFT", "PB") {
        token = PiggyToken(_token);
    }

    /**
     * @dev Sets the PiggyBank tiers.
     * @param _tierId The ID of the tier.
     * @param _lockingPeriod The period of time for which the tokens are locked.
     * @param _bonusPercentage The bonus percentage that users receive.
     */

    function setTiers(
        uint _tierId,
        uint _lockingPeriod,
        uint _bonusPercentage
    ) external onlyOwner {
        require(_lockingPeriod > 0, "Locking period must be greater than 0");
        require(tiers[_tierId].lockingPeriod == 0, "Tier id already exists");
        tiers[_tierId] = PiggyBankTier(_lockingPeriod, _bonusPercentage);
    }

    /**
     * @dev Mints a PiggyBankNFT token.
     * @param _tierId The ID of the PiggyBank tier.
     * @param uri The URI of the PiggyBankNFT token.
     */

    function mintPiggyBankNFT(uint _tierId, string memory uri) external {
        require(tiers[_tierId].lockingPeriod > 0, "Invalid tier");
        _tokenIds.increment();
        uint newTokenId = _tokenIds.current();
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, uri);
        tokenIdTotierId[newTokenId] = _tierId;
        isActive[msg.sender][newTokenId] = true;

        emit PiggyBankNFTCreated(msg.sender, newTokenId, _tierId);
    }

    /**
@dev Locks funds for a specific NFT
@param _user The address of the user who is locking the funds
@param _amount The amount of funds to be locked
@param _nftId The ID of the NFT
*/
    function lock(address _user, uint _amount, uint _nftId) external {
        require(_amount > 0, "Amount must be greater than 0");
        uint _tierId = tokenIdTotierId[_nftId];
        require(tiers[_tierId].lockingPeriod > 0, "Invalid tier");

        locks[_nftId] = Lock(
            _user,
            _amount,
            tiers[_tierId].lockingPeriod,
            tiers[_tierId].bonusPercentage,
            block.timestamp,
            false
        );
        emit TokensLocked(
            _user,
            _amount,
            tiers[_tierId].lockingPeriod,
            tiers[_tierId].bonusPercentage
        );
    }

    /**
@dev Withdraws locked funds for a specific NFT
@param _tokenId The ID of the NFT
*/

    function cashOut(uint _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner");

        Lock storage depo = locks[_tokenId];
        require(depo.amount > 0, "No deposit found");
        require(!depo.isCompleted, "Already cashed out");

        uint elapsed = block.timestamp - depo.startTime;
        require(elapsed > depo.lockingPeriod, "Tokens are still locked");

        uint bonusAmount = (depo.amount * depo.bonusPercentage) / 100;
        uint withdrawAmount = depo.amount + bonusAmount;
        require(
            token.balanceOf(address(this)) >= withdrawAmount,
            "Insufficient funds in NFT locking pool"
        );

        token.transfer(msg.sender, withdrawAmount);

        depo.isCompleted = true;
        _burn(_tokenId);

        emit NFTCashedOut(_tokenId, msg.sender, withdrawAmount);
    }

    function getBalanceByTokenId(uint _tokenId) public view returns (uint) {
        Lock storage depo = locks[_tokenId];
        require(depo.amount > 0, "No deposit found");
        uint elapsed = block.timestamp - depo.startTime;
        uint bonusAmount = 0;
        if (elapsed > depo.lockingPeriod) {
            bonusAmount = (depo.amount * depo.bonusPercentage) / 100;
            bonusAmount += depo.amount;
        } else {
            bonusAmount = depo.amount;
        }
        return bonusAmount;
    }

    //override functions
    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    //withdraw function
    function withdraw(uint _amount) public onlyOwner {
        require(
            token.balanceOf(address(this)) > _amount,
            "Insufficient funds in contract"
        );
        token.transfer(msg.sender, _amount);
    }
}
