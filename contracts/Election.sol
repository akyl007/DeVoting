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
    bool public electionActive;

    // События
    event CandidateAdded(uint indexed candidateId, string name);
    event CandidateRemoved(uint indexed candidateId);
    event VotedEvent(uint indexed candidateId, address indexed voter);
    event VoterRegistered(address indexed voter);
    event ElectionStarted();
    event ElectionEnded();
    event ElectionReset();

    constructor() public {
        electionActive = true;
        emit ElectionStarted();
        addCandidate("Shamid");
        addCandidate("Yakhiyayeva Marzhan");
        addCandidate("Akylbek Mendibayev");
        addCandidate("Adylbekova Zhanel");
        addCandidate("Mustafa Akerke");
    }

    function addCandidate(string memory _name) private {
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
        emit CandidateAdded(candidatesCount, _name);
    }

    function removeCandidate(uint _candidateId) public {
        require(_candidateId > 0 && _candidateId <= candidatesCount, "Invalid candidate ID");
        delete candidates[_candidateId];
        emit CandidateRemoved(_candidateId);
    }

    function registerVoter(address _voter) public {
        require(!voters[_voter], "Voter already registered");
        voters[_voter] = true;
        emit VoterRegistered(_voter);
    }

    function vote(uint _candidateId) public {
        require(electionActive, "Election is not active");
        require(!voters[msg.sender], "Voter already voted");
        require(_candidateId > 0 && _candidateId <= candidatesCount, "Invalid candidate ID");

        voters[msg.sender] = true;
        candidates[_candidateId].voteCount++;

        emit VotedEvent(_candidateId, msg.sender);
    }

    function endElection() public {
        require(electionActive, "Election already ended");
        electionActive = false;
        emit ElectionEnded();
    }

    function resetElection() public {
        electionActive = true;
        for (uint i = 1; i <= candidatesCount; i++) {
            candidates[i].voteCount = 0;
        }
        for (uint i = 1; i <= candidatesCount; i++) {
            voters[address(i)] = false;
        }
        emit ElectionReset();
    }
}
