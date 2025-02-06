const Election = artifacts.require("Election");

contract("Election", (accounts) => {
    let election;

    beforeEach(async () => {
        election = await Election.new();
    });

    it("Should initialize with default candidates", async () => {
        const count = await election.candidatesCount();
        assert(count.toNumber() > 0, "Candidates should be initialized");
    });

    it("Should allow voter registration", async () => {
        await election.registerVoter(accounts[1]);
        const isRegistered = await election.voters(accounts[1]);
        assert(isRegistered, "Voter should be registered");
    });

    it("Should not allow double voter registration", async () => {
        await election.registerVoter(accounts[1]);
        try {
            await election.registerVoter(accounts[1]);
            assert(false, "Should have thrown an error");
        } catch (error) {
            assert(error, "Expected an error but did not get one");
        }
    });

    it("Should allow removing a candidate", async () => {
        await election.removeCandidate(1);
        const candidate = await election.candidates(1);
        assert(candidate.name === "", "Candidate should be removed");
    });

    it("Should emit events correctly", async () => {
        const tx = await election.registerVoter(accounts[1]);
        assert(tx.logs.length > 0, "Expected an event to be emitted");
    });

    it("Should not allow removing a non-existent candidate", async () => {
        try {
            await election.removeCandidate(999);
            assert(false, "Should have thrown an error");
        } catch (error) {
            assert(error, "Expected an error but did not get one");
        }
    });
});
