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
        uint256 votedProposalId;
    }

    struct Proposal {
        string description;
        uint256 voteCount;
    }

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    uint256 whitelistedNumber;
    WorkflowStatus public status;
    mapping(address => Voter) whitelist;
    Proposal[] public proposals;

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(
        WorkflowStatus previousStatus,
        WorkflowStatus newStatus
    );
    event ProposalRegistered(uint256 proposalId);
    event Voted(address voter, uint256 proposalId);

    //constructor add owner to whitelist at deployment
    constructor() {
        addToWhitelist(msg.sender);
    }

    modifier onlyRegistered() {
        require(whitelist[msg.sender].isRegistered, "You are not registered");
        _;
    }

    modifier votable() {
        require(!whitelist[msg.sender].hasVoted, "You've already voted");
        _;
    }

    /*
     * @dev check if the current status match with a given status index
     * @param _index of the WorkflowStatus to compare
     */
    function checkStatus(uint8 _index) private view {
        require(uint8(status) == _index, "Not authorized");
    }

    /*
     * @dev incremente voting status
     */
    function incrementStatus() private {
        status = WorkflowStatus(uint8(status) + 1);
        emit WorkflowStatusChange(WorkflowStatus(uint8(status) - 1), status);
    }

    /*
     * @dev onlyOwner Add to whitelist a new voter
     * @param _voterAddress ethereum address of the new voter
     */
    function addToWhitelist(address _voterAddress) public onlyOwner {
        checkStatus(0);
        require(
            !whitelist[_voterAddress].isRegistered,
            "Voter is already registered"
        );
        Voter memory newVoter = Voter(true, false, 0);
        whitelist[_voterAddress] = newVoter;
        whitelistedNumber++;
        emit VoterRegistered(_voterAddress);
    }

    /*
     * @dev onlyOwner start proposal registration process by incrementing the status
     */
    function startProposalsRegistration() external onlyOwner {
        checkStatus(0);
        require(
            whitelistedNumber > 1,
            "Must be at least 2 voters to start the process"
        );
        incrementStatus();
    }

    /*
     * @dev allow registred voters to register new proposal
     * @param _description a string of minimum 10 characters
     */
    function registerProposal(string calldata _description)
        external
        onlyRegistered
    {
        checkStatus(1);
        require(
            bytes(_description).length > 10,
            "Proposal description is to short"
        );
        Proposal memory proposal = Proposal(_description, 0);
        proposals.push(proposal);
        uint256 proposalId = proposals.length - 1;
        emit ProposalRegistered(proposalId);
    }

    /*
     * @dev onlyOwner end proposal registration by incrementing the status
     */
    function endProposalsRegistration() external onlyOwner {
        checkStatus(1);
        require(proposals.length > 0, "There's not yet any proposal to vote");
        incrementStatus();
    }

    /*
     * @dev onlyOwner start voting session by incrementing the status
     */
    function startVotingSession() external onlyOwner {
        checkStatus(2);
        incrementStatus();
    }

    /*
     * @dev allow a whitelisted member who has not already voted to vote for a proposal
     * @param _proposalId
     */
    function vote(uint256 _proposalId) external votable onlyRegistered {
        checkStatus(3);
        require(
            _proposalId >= 0 && _proposalId < proposals.length,
            "proposal id is not valid"
        );
        Voter memory updatedVoter = Voter(true, true, _proposalId);
        proposals[_proposalId].voteCount++;
        whitelist[msg.sender] = updatedVoter;
        emit Voted(msg.sender, _proposalId);
    }

    /*
     * @dev end voting session by incrementing the status
     */
    function endVotingSession() external onlyOwner {
        checkStatus(3);
        incrementStatus();
    }

    /*
     * @dev get the winner
     * @return voting proposal
     */
    function getWinner() external returns (Proposal memory) {
        checkStatus(4);
        Proposal memory winningProposal;
        bool equality;
        for (uint8 i; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningProposal.voteCount) {
                winningProposal = proposals[i];
            } else if (
                i > 0 &&
                proposals[i].voteCount != 0 &&
                proposals[i].voteCount == winningProposal.voteCount
            ) {
                equality = true;
            }
        }
        incrementStatus();
        if (equality) {
            revert("Equality in votes!");
        } else if (winningProposal.voteCount == 0) {
            revert("No voters");
        }
        return winningProposal;
    }
}
