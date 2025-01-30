pragma solidity >=0.4.22 <0.6.0;

contract Election{
    //model the candidate
    struct Candidate{
        uint id;
        string name;
        uint voteCount;
    }
    //store candidates
    //store accounts that have voted
    mapping(address => bool) public voters;

    //fetch candidate
    mapping(uint => Candidate) public candidates;
    //store candidates count
    uint public candidatesCount;

    //voted event
    event votedEvent(
        uint indexed_candidateId
    );

    string  public candidate;
    //constructor
    constructor () public{
        // candidate = "Rahul Gandhi";
        addCandidate("Shamid");
        addCandidate("Yakhiyayeva Marzhan");
        addCandidate("Akylbek Mendibayev");
        addCandidate("Adylbekova Zhanel ");
        addCandidate("Mustafa Akerke");
    }

    function addCandidate (string memory _name) private{
        candidatesCount++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
    }

    function vote(uint _candidateId) public{
        //require that they haven't voted before
        require(!voters[msg.sender], "Voter already voted");

        //require a valid candidate
        require(_candidateId > 0 && _candidateId <= candidatesCount, "Invalid Id");

        //record that the voter has voted
        voters[msg.sender] = true;

        //update Candidate vote count
        candidates[_candidateId].voteCount++;

        //trigger voted event
        emit votedEvent(_candidateId);
    }
}