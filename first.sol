// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import "@thirdweb-dev/contracts/base/ERC721Base.sol";

abstract contract Adminable is Ownable{
    mapping (address => bool) public admin;
    modifier onlyAdmin() {
        require(admin[msg.sender], "Adminable: caller is not the admin");
        _;
    }
    function addadmin(address newAdmin) public virtual onlyOwner {
        admin[newAdmin] = true;
    }
    function canceladmin(address newAdmin) public virtual onlyOwner {
        admin[newAdmin] = false;
    }
}

contract IsekaiGenesis is ERC721Base,Adminable  {

    using Strings for uint256;
    bytes32 public ogRoot;
    bytes32 public wlRoot;

    string public uriPrefix = '';
    string public uriSuffix = '';
    string public hiddenMetadataUri = '';
    
    uint256 public mintCost = 0.03 ether;
    uint256 public ogMintCost = 0.00 ether;
    uint256 public wlMintCost = 0.00 ether;

    uint256 public publicSupply = 4855;
    uint256 public onwerSupply = 700;
    uint256 public publicMintCount = 0;
    uint256 public onwerMintCount = 0;

    mapping(address => uint256) public wlMintCount;
    mapping(address => uint256) public ogMintCount;
    mapping(address => uint256) public mintCount;
    uint256 public mintLimit = 1;
    uint256 public wlMintLimit = 1;
    uint256 public ogMintLimit = 1;

    bool public OGpaused = true;
    bool public WLpaused = true;
    bool public paused = true;
    bool public revealed = false;

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps
    )
        ERC721Base(
            _name,
            _symbol,
            _royaltyRecipient,
            _royaltyBps
        )
    {
        addadmin(msg.sender);
    }

    function whitelistMint(bytes32[] calldata _merkleProof) public payable {
        require(!WLpaused, 'whitelistMint is paused!');
        require(publicMintCount+1<=publicSupply, 'Max supply exceeded!');
        require(wlMintCount[msg.sender]+1<=wlMintLimit, 'Address already minted!');
        require(msg.value >= wlMintCost, "insufficient funds");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, wlRoot, leaf), 'Invalid proof!');
        wlMintCount[msg.sender]+=1;
        publicMintCount+=1;
        _safeMint(msg.sender, 1);
    }

    function ogMint(bytes32[] calldata _merkleProof) public payable {
        require(!OGpaused, 'ogMint is paused!');
        require(publicMintCount+1<=publicSupply, 'Max supply exceeded!');
        require(ogMintCount[msg.sender]+1<=ogMintLimit, 'Address already minted!');
        require(msg.value >= ogMintCost, "insufficient funds");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, ogRoot, leaf), 'Invalid proof!');
        ogMintCount[msg.sender]+=1;
        publicMintCount+=1;
        _safeMint(msg.sender, 1);
    }

    function mint() public payable {
        require(!paused, 'mint is paused!');
        require(publicMintCount+1<=publicSupply, 'Max supply exceeded!');
        require(mintCount[msg.sender]+1<=mintLimit, 'Address already minted!');
        require(msg.value >= mintCost, "insufficient funds");
        _safeMint(msg.sender, 1);
        publicMintCount+=1;
        mintCount[msg.sender]+=1;
    }
    
    function ownerMint(address _receiver,uint256 amount) public onlyAdmin {
        require(onwerMintCount+amount<=onwerSupply, 'owner supply exceeded!');
        _safeMint(_receiver, amount);
        onwerMintCount+=amount;
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');
        if (revealed == false) {
            return hiddenMetadataUri;
        }
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, (_tokenId+1).toString(), uriSuffix))
            : '';
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return uriPrefix;
    }

    function setRevealed(bool _state) public onlyAdmin {
        revealed = _state;
    }
    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyAdmin {
        hiddenMetadataUri = _hiddenMetadataUri;
    }
    function setUriPrefix(string memory _uriPrefix) public onlyAdmin {
        uriPrefix = _uriPrefix;
    }
    function setUriSuffix(string memory _uriSuffix) public onlyAdmin {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyAdmin {
        paused = _state;
    }
    function setOGPaused(bool _state) public onlyAdmin {
        OGpaused = _state;
    }
    function setWLPaused(bool _state) public onlyAdmin {
        WLpaused = _state;
    }

    function setOgRoot(bytes32 _ogRoot) public onlyAdmin {
        ogRoot = _ogRoot;
    }
    function setWlRoot(bytes32 _wlRoot) public onlyAdmin {
        wlRoot = _wlRoot;
    }

    function setMintCost(uint256 _mintCost) public onlyAdmin {
        mintCost = _mintCost;
    }
    function setOgMintCost(uint256 _ogMintCost) public onlyAdmin {
        ogMintCost = _ogMintCost;
    }
    function setWlMintCost(uint256 _wlMintCost) public onlyAdmin {
        wlMintCost = _wlMintCost;
    }

    function setPublicSupply(uint256 _publicSupply) public onlyAdmin {
        publicSupply = _publicSupply;
    }
    function setOnwerSupply(uint256 _onwerSupply) public onlyAdmin {
        onwerSupply = _onwerSupply;
    }

    function setMintLimit(uint256 _mintLimit) public onlyAdmin {
        mintLimit = _mintLimit;
    }
    function setWlMintLimit(uint256 _wlMintLimit) public onlyAdmin {
        wlMintLimit = _wlMintLimit;
    }
    function setOgMintLimit(uint256 _ogMintLimit) public onlyAdmin {
        ogMintLimit = _ogMintLimit;
    }
    
    function withdraw(address recipient) public onlyAdmin {
        (bool hs, ) = payable(recipient).call{value: address(this).balance}("");
        require(hs);
    }
}
