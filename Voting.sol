// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/*
* @author Samir
* @notice Satoshi promo Project1
*/
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

    uint8 whitelistNumber;
    WorkflowStatus public status;
    mapping(address => Voter) whitelist;
    Proposal[] public proposals;

    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    constructor() {
        addToWhitelist(msg.sender);
    }

    modifier onlyRegistered() {
        require(whitelist[msg.sender].isRegistered, "You are not registered");
        _;
    }

    modifier votable()  {
        require(!whitelist[msg.sender].hasVoted, "You've already voted");
        _;
    }


    /*
    * @dev check if an address is registred in the withelist
    * @param _index of the WorkflowStatus
    */
    function checkStatus(uint8 _index) private view  {
        require(uint8(status) == _index,"Not authorized");
    }

    /*
    * @dev incremente status
    */
    function incrementStatus() private  {
        status = WorkflowStatus(uint8(status) + 1);
        emit WorkflowStatusChange(WorkflowStatus(uint8(status) - 1), status);
    }

    /*
    * @dev Add to whitelist a new voter
    * @param _voterAddress ethereum address of the new voter
    */
    function addToWhitelist(address _voterAddress) public onlyOwner {
        checkStatus(0);
        require(!whitelist[_voterAddress].isRegistered, "Voter is already registered");
        Voter memory newVoter = Voter(true,false,0);
        whitelist[_voterAddress] = newVoter;
        whitelistNumber++;
        emit VoterRegistered(_voterAddress);
    }

    /*
    * @dev start proposal registration process by incrementing the status
    */
    function startProposalsRegistration() external onlyOwner {
        checkStatus(0);
        require(whitelistNumber > 1, "Must be at least 2 voters to start the process");
        incrementStatus();
    }

    /*
    * @dev
    * @param
    */
    function registerProposal(string memory _description) external onlyRegistered {
        checkStatus(1);
        require(bytes(_description).length > 10, "Proposal description is to short");
        Proposal memory proposal = Proposal(_description,0);
        proposals.push(proposal);
        uint proposalId = proposals.length - 1;
        emit ProposalRegistered(proposalId);
    }

    /*
    * @dev
    */
    function endProposalsRegistration() external onlyOwner {
        checkStatus(1);
        require(proposals.length > 0, "There's not yet any proposal to vote");
        incrementStatus();
    }

    /*
    * @dev
    */
    function startVotingSession() external onlyOwner {
        checkStatus(2);
        incrementStatus();
    }

    /*
    * @dev
    * @param
    */
    function vote(uint _proposalId) external votable onlyRegistered {
        checkStatus(3);
        require(_proposalId >= 0 && _proposalId < proposals.length, "proposal id is not valide");
        Voter memory updatedVoter = Voter(true,true,_proposalId);
        proposals[_proposalId].voteCount++;
        whitelist[msg.sender] = updatedVoter;
        emit Voted(msg.sender,_proposalId);
    }

    /*
    * @dev
    */
    function endVotingSession() external onlyOwner  {
        checkStatus(3);
        incrementStatus();
    }

    /*
    * @dev
    * @param
    * @return
    */
    function getWinner() external returns(Proposal memory){
        checkStatus(4);
        Proposal memory winningProposal;
        bool equality;
        for(uint8 i;i < proposals.length;i++){
            if(proposals[i].voteCount > winningProposal.voteCount){
                winningProposal = proposals[i];
            } else if(i > 0 && proposals[i].voteCount != 0 && proposals[i].voteCount == winningProposal.voteCount){
                equality = true;
            }
        }
        incrementStatus();
        if(equality){
            revert("Equality in votes!");
        }else if(winningProposal.voteCount == 0) {
            revert("No voters");
        }
        return winningProposal;
    }

}

