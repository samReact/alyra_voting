// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    uint whitelistNumber;
    WorkflowStatus public status;
    uint[] equalIds;

    mapping(address => Voter) whitelist;
    Proposal[] public proposals;

    // events
    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    // modifiers
    modifier votable(address _voterAddress) {
        require(status == WorkflowStatus.VotingSessionStarted, "Voting session not started");
        require(isRegistered(_voterAddress), "You are not registered");
        require(!whitelist[msg.sender].hasVoted, "You've already voted");
        _;
    }

    modifier proposable(address _voterAddress,string memory _description){
        require(status == WorkflowStatus.ProposalsRegistrationStarted, "Proposal registration not started");
        require(isRegistered(_voterAddress), "You are not registered");
        require(bytes(_description).length > 0, "Proposal description should not be empty");
        _;
    }
    //functions
    function isRegistered(address _voterAddress) internal view returns(bool){
        return whitelist[_voterAddress].isRegistered;
    }


    function addToWhitelist(address _voterAddress) public onlyOwner {
        require(status == WorkflowStatus.RegisteringVoters, "Voter registration is not open");
        require(!isRegistered(_voterAddress), "Voter is already registered");
        Voter memory newVoter = Voter(true,false,0);
        whitelist[_voterAddress] = newVoter;
        whitelistNumber++;
        emit VoterRegistered(_voterAddress);
    }

    function startProposalsRegistration() public onlyOwner {
        require(status == WorkflowStatus.RegisteringVoters, "Voter registration is not open");
        require(whitelistNumber > 0, "No registered voter to start registering proposals");
        status = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    function registerProposal(string memory _description) public proposable(msg.sender,_description){
        Proposal memory proposal = Proposal(_description,0);
        proposals.push(proposal);
        uint proposalId = proposals.length;
        emit ProposalRegistered(proposalId);
    }

    function endProposalsRegistration() public onlyOwner {
        require(status == WorkflowStatus.ProposalsRegistrationStarted, "No proposal registration to close");
        require(proposals.length > 0, "There's not yet any proposal to vote");
        status = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded);
    }

    function startVotingSession() public onlyOwner {
        require(status == WorkflowStatus.ProposalsRegistrationEnded, "Voter proposal registration not closed");
        status = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded,WorkflowStatus.VotingSessionStarted);
    }


    function vote(uint _proposalId) public  votable(msg.sender) {
        require(_proposalId >= 0 && _proposalId < proposals.length, "proposal id is not valide");
        Voter memory updatedVoter = Voter(true,true,_proposalId);
        proposals[_proposalId].voteCount++;
        whitelist[msg.sender] = updatedVoter;
        emit Voted(msg.sender,_proposalId);
    }

    function endVotingSession() public onlyOwner  {
        require(status == WorkflowStatus.VotingSessionStarted, "Voting session not started");
        status = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }

    function getWinner() public returns(Proposal memory){
        require(status == WorkflowStatus.VotingSessionEnded, "Voting session is not finished");
        Proposal memory winningProposal;
        for(uint i;i < proposals.length;i++){
            if(proposals[i].voteCount > winningProposal.voteCount){
                winningProposal = proposals[i];
            } else if(i > 0 && proposals[i].voteCount == winningProposal.voteCount){
                equalIds.push(i);
            }
        }
        if(equalIds.length > 0){
            revert("Equality in votes!");
        }
        status = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
        return winningProposal;
    }

}

