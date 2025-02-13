pragma solidity >=0.4.22 <0.6.0;

contract Election {
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }

    mapping(uint => Candidate) public candidates;
    mapping(address => bool) public voters;
    uint public candidatesCount;
    uint256 private flags; // electionActive и locked можно хранить здесь
    address public admin;
    mapping(address => bool) public moderators;


    event CandidateAdded(uint indexed candidateId, string name);
    event CandidateRemoved(uint indexed candidateId);
    event VotedEvent(uint indexed candidateId, address indexed voter);
    event VoterRegistered(address indexed voter);
    event ElectionStarted();
    event ElectionEnded();
    event ElectionReset();
    event ModeratorAdded(address indexed moderator);
    event ModeratorRemoved(address indexed moderator);


    string constant INVALID_CANDIDATE_ID = "Invalid candidate ID";
    string constant INVALID_NAME_LENGTH = "Invalid name length (0-32 chars)";
    string constant NEGATIVE_VALUE = "Negative value not allowed";
    string constant DUPLICATE_VOTER = "Voter already exists";
    string constant UNAUTHORIZED = "Unauthorized access";
    string constant ELECTION_NOT_ACTIVE = "Election is not active";
    string constant ELECTION_ALREADY_ACTIVE = "Election is already active";
    string constant CANDIDATE_REMOVED = "Candidate already removed";
    string constant ADMIN_PROTECTED = "Cannot remove admin";
    string constant INVALID_VOTE = "Invalid vote count";


    uint256 private constant ELECTION_ACTIVE_FLAG = 1;
    uint256 private constant LOCKED_FLAG = 2;

    modifier onlyAdmin() {
        require(msg.sender == admin, UNAUTHORIZED);
        _;
    }
    
    modifier onlyModerator() {
        require(moderators[msg.sender], UNAUTHORIZED);
        _;
    }


    modifier noReentrant() {
        require(!locked(), "Reentrant call detected");
        setLocked(true);
        _;
        setLocked(false);
    }
    

    modifier safeOperations(uint a, uint b) {
        require(a + b >= a, "Overflow detected");
        _;
    }
    
   
    modifier validAddress(address _address) {
        require(_address != address(0), "Invalid address");
        _;
    }

    modifier validVoter(uint _candidateId) {
        require(isElectionActive(), ELECTION_NOT_ACTIVE);
        require(!voters[msg.sender], DUPLICATE_VOTER);
        require(_candidateId > 0 && _candidateId <= candidatesCount, INVALID_CANDIDATE_ID);
        require(candidates[_candidateId].id != 0, CANDIDATE_REMOVED);
        _;
    }

    constructor() public {
        admin = msg.sender;
        moderators[msg.sender] = true;
        setElectionActive(true);
        emit ElectionStarted();
        addCandidate("Shamid");
        addCandidate("Yakhiyayeva Marzhan");
        addCandidate("Akylbek Mendibayev");
        addCandidate("Adylbekova Zhanel");
        addCandidate("Mustafa Akerke");
    }

    function addCandidate(string memory _name) private {
        uint256 nameLength = bytes(_name).length;
        require(nameLength > 0 && nameLength <= 32, INVALID_NAME_LENGTH);
        require(candidatesCount + 1 > candidatesCount, NEGATIVE_VALUE);
        
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
        emit CandidateAdded(candidatesCount, _name);
    }

    function removeCandidate(uint _candidateId) public onlyModerator {
        require(_candidateId > 0 && _candidateId <= candidatesCount, INVALID_CANDIDATE_ID);
        require(candidates[_candidateId].id != 0, CANDIDATE_REMOVED);
        
        candidates[_candidateId].name = "";
        candidates[_candidateId].voteCount = 0;
        
        emit CandidateRemoved(_candidateId);
    }

    function registerVoter(address _voter) public onlyModerator validAddress(_voter) {
        require(!voters[_voter], DUPLICATE_VOTER);
        voters[_voter] = true;
        emit VoterRegistered(_voter);
    }

    function vote(uint _candidateId) public noReentrant validVoter(_candidateId) {
        voters[msg.sender] = true;
        uint256 newVoteCount = safeAdd(candidates[_candidateId].voteCount, 1);
        require(newVoteCount > candidates[_candidateId].voteCount, INVALID_VOTE);
        candidates[_candidateId].voteCount = newVoteCount;

        emit VotedEvent(_candidateId, msg.sender);
    }

    function endElection() public onlyAdmin {
        require(isElectionActive(), ELECTION_NOT_ACTIVE);
        setElectionActive(false);
        emit ElectionEnded();
    }

    function resetElection() public onlyAdmin {
        require(!isElectionActive(), ELECTION_ALREADY_ACTIVE);
        
        for (uint i = 1; i <= candidatesCount; i++) {
            candidates[i].voteCount = 0;
            voters[address(i)] = false;
        }
        
        setElectionActive(true);
        emit ElectionReset();
    }

    function addModerator(address _moderator) public onlyAdmin validAddress(_moderator) {
        require(!moderators[_moderator], "Already a moderator");
        moderators[_moderator] = true;
        emit ModeratorAdded(_moderator);
    }

    function removeModerator(address _moderator) public onlyAdmin {
        require(moderators[_moderator], "Not a moderator");
        require(_moderator != admin, "Cannot remove admin from moderators");
        moderators[_moderator] = false;
        emit ModeratorRemoved(_moderator);
    }

    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, NEGATIVE_VALUE);
        return c;
    }

    function isElectionActive() internal view returns (bool) {
        return (flags & ELECTION_ACTIVE_FLAG) == ELECTION_ACTIVE_FLAG;
    }

    function setElectionActive(bool _active) internal {
        if(_active) {
            flags = flags | ELECTION_ACTIVE_FLAG;
        } else {
            flags = flags & ~ELECTION_ACTIVE_FLAG;
        }
    }

    function locked() internal view returns (bool) {
        return (flags & LOCKED_FLAG) == LOCKED_FLAG;
    }

    function setLocked(bool _locked) internal {
        if(_locked) {
            flags = flags | LOCKED_FLAG;
        } else {
            flags = flags & ~LOCKED_FLAG;
        }
    }

    function getCandidateCount() public view returns (uint) {
        uint activeCount = 0;
        for (uint i = 1; i <= candidatesCount; i++) {
            if (bytes(candidates[i].name).length > 0) {
                activeCount++;
            }
        }
        return activeCount;
    }
}
