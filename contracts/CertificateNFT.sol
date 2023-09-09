// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract CertificateNFT is ERC721, ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter public certificateCounter;

    struct Certificate {
        string ownerName;
        string docName;
        string data; // (just small description about certificate)
        bool validated;
        uint256 tokenId;
        string ipfsAddress;
    }

    // account data
    mapping(address => bool) public GovernmentAccounts;
    mapping(address => bool) public InduvitualsAccounts;

    // certificates details data
    mapping(address => Certificate) public certificates;

    // Events to log important contract actions
    event CertificateUploaded(
        address indexed owner,
        uint256 indexed certificateId
    );
    event CertificateValidated(uint256 indexed certificateId, bool validated);

    // ====== ERC-721 NFT token name, symbol and baseURI defined =====
    constructor() ERC721("CertificateNFT", "CNFT") {}

    function _baseURI() internal pure override returns (string memory) {
        return "http://localhost:8000/";
    }

    // ====== allocate the role for the given address =====
    function grantGovernmentPrivilege(address _account) public {
        require(address(0) == _account, "need to send a valid address");
        GovernmentAccounts[_account] = true;
    }

    function grantInduvitualsPrivilege(address _account) public {
        require(address(0) == _account, "need to send a valid address");
        InduvitualsAccounts[_account] = true;
    }

    // ===== based on their role specific task they can do =====
    modifier onlyGovernment() {
        require(
            GovernmentAccounts[msg.sender] == true,
            "only government authority can use this function"
        );
        _;
    }

    modifier onlyInduvituals() {
        require(
            InduvitualsAccounts[msg.sender] == true,
            "only Induvituals can use this function"
        );
        _;
    }

    function isStringValid(string memory _str) internal pure returns (bool) {
        bytes memory strBytes = bytes(_str);
        return strBytes.length > 0;
    }

    // Induvituals functionalities
    function mintDocument(
        address _to,
        string memory _ownerName,
        string memory _docName,
        string memory _data,
        string memory _ipfsAddress,
        string memory _URI
    ) public onlyInduvituals {
        require(
            InduvitualsAccounts[_to] == true,
            "to address must be a Induvituals"
        );
        require(isStringValid(_ownerName), "Input _ownerName string is empty");
        require(isStringValid(_docName), "Input _docName string is empty");
        require(isStringValid(_data), "Input _data string is empty");
        require(
            isStringValid(_ipfsAddress),
            "Input _ipfsAddress string is empty"
        );
        require(isStringValid(_URI), "Input _URI string is empty");

        uint256 tokenId = certificateCounter.current();
        // mint NFT token
        _safeMint(_to, tokenId);

        // Set the metadata URI for the NFT
        _setTokenURI(tokenId, _URI);

        certificates[_to] = Certificate(
            _ownerName,
            _docName,
            _data,
            false,
            tokenId,
            _ipfsAddress
        );
        certificateCounter.increment();
        emit CertificateUploaded(_to, tokenId);
    }

    // property listings
    uint256 propertyListingCount;
    struct PropertyListing {
        address owner;
        string ownerName;
        uint256 price;
        string docName;
        string data;
        bool validated;
        string ipfsAddress;
        bool isActive;
    }

    mapping(uint256 => PropertyListing) public propertyListings;
    // mapping(address => uint256[]) public digitalLocker;

    event PropertyTransferred(
        uint256 indexed tokenId,
        address indexed from,
        address indexed to
    );
    event PropertyListed(address indexed ownerAddress, uint256 price);
    event PropertyPurchasedFromMarketplace(
        address oldOwner,
        address indexed newOwner,
        uint256 _price,
        uint256 tokenId
    );

    // token checking
    modifier tokenCheck() {
        uint256 tokenId = certificates[msg.sender].tokenId;
        require(_exists(tokenId), "Token does not exist");
        require(ownerOf(tokenId) == msg.sender, "Not the token owner");
        _;
    }

    function createPropertyListing(
        string memory _ownerName,
        uint256 _price,
        string memory _docName,
        string memory _data,
        bool _isValidated,
        string memory _ipfsAddress
    ) public onlyInduvituals tokenCheck {
        require(_price > 0, "Invalid price amount");
        require(isStringValid(_ownerName), "Input _ownerName string is empty");
        require(isStringValid(_docName), "Input _docName string is empty");
        require(isStringValid(_data), "Input _data string is empty");
        require(
            isStringValid(_ipfsAddress),
            "Input _ipfsAddress string is empty"
        );

        propertyListings[propertyListingCount] = PropertyListing(
            msg.sender,
            _ownerName,
            _price,
            _docName,
            _data,
            _isValidated,
            _ipfsAddress,
            true
        );
        propertyListingCount += 1;
        emit PropertyListed(msg.sender, _price);
    }

    function purchaseProperty(uint256 _tokenId)
        public
        payable
        onlyInduvituals
        tokenCheck
    {
        require(_tokenId > 0, "Invalid _tokenId value");
        PropertyListing storage listing = propertyListings[_tokenId];

        require(listing.isActive, "Listing is not active");
        require(
            msg.value >= listing.price,
            "Insufficient funds to purchase the property"
        );

        address oldOwner = ownerOf(_tokenId);
        require(oldOwner != msg.sender, "You already own this property");

        // Transfer ownership of the NFT to the new owner
        safeTransferFrom(oldOwner, msg.sender, _tokenId);

        payable(oldOwner).transfer(msg.value);

        listing.isActive = false;

        emit PropertyPurchasedFromMarketplace(
            oldOwner,
            msg.sender,
            msg.value,
            _tokenId
        );
    }

    // track digital lockers for each user
    mapping(address => mapping(uint256 => bool)) private digitalLocker;

    event DigitalLockerUpdated(
        address indexed owner,
        uint256 tokenId,
        bool added
    );

    function addToDigitalLocker(uint256 _tokenId)
        external
        onlyInduvituals
        tokenCheck
    {
        require(_tokenId > 0, "Invalid _tokenId value");
        require(ownerOf(_tokenId) == msg.sender, "You don't own this token");
        require(
            !digitalLocker[msg.sender][_tokenId],
            "Token is already in the digital locker"
        );

        digitalLocker[msg.sender][_tokenId] = true;
        emit DigitalLockerUpdated(msg.sender, _tokenId, true);
    }

    function removeFromDigitalLocker(uint256 _tokenId)
        external
        onlyInduvituals
        tokenCheck
    {
        require(_tokenId > 0, "Invalid _tokenId value");
        require(ownerOf(_tokenId) == msg.sender, "You don't own this token");
        require(
            digitalLocker[msg.sender][_tokenId],
            "Token is not in the digital locker"
        );

        digitalLocker[msg.sender][_tokenId] = false;
        emit DigitalLockerUpdated(msg.sender, _tokenId, false);
    }

    function isInDigitalLocker(address _owner, uint256 _tokenId)
        public
        view
        returns (bool)
    {
        require(_owner > address(0), "Invalid _owner address");
        require(_tokenId > 0, "Invalid _tokenId value");
        return digitalLocker[_owner][_tokenId];
    }

    struct VerificationRequest {
        address requester;
        address governmentAddress;
        uint256 tokenId;
        bool isVerified;
    }

    mapping(uint256 => VerificationRequest) public verificationRequests;
    uint256 public verificationRequestId;

    event DocumentVerificationRequested(
        uint256 indexed requestId,
        address indexed requester,
        address indexed governmentAddress,
        uint256 tokenId
    );

    event DocumentVerificationResult(
        uint256 indexed requestId,
        address indexed requester,
        bool _isValid
    );

    function requestDocumentVerification(uint256 _tokenId, address _govAddress)
        external
        onlyInduvituals
        tokenCheck
    {
        require(
            GovernmentAccounts[_govAddress] == true,
            "Invalid government address"
        );
        require(_tokenId > 0, "Invalid _tokenId value");

        verificationRequests[verificationRequestId++] = VerificationRequest(
            msg.sender,
            _govAddress,
            _tokenId,
            false
        );

        emit DocumentVerificationRequested(
            verificationRequestId,
            msg.sender,
            _govAddress,
            _tokenId
        );
    }

    // Government functionalities

    function validateDocumentVerification(uint256 _requestId, bool _isValid)
        external
        onlyGovernment
    {
        require(_requestId > 0, "Invalid _tokenId value");
        VerificationRequest storage request = verificationRequests[_requestId];
        require(request.requester != address(0), "Invalid request ID");
        require(!request.isVerified, "Request already verified");

        if (_isValid) {
            request.isVerified = true;
        }

        emit DocumentVerificationResult(
            _requestId,
            request.requester,
            _isValid
        );
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
        onlyInduvituals
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
