App = {
  web3Provider: null,
  contracts: {},
  account: '0x0',
  isTransactionPending: false,

  init: function() {
    return App.initWeb3();
  },

  initWeb3: async function() {
    if (window.ethereum) {
      App.web3Provider = window.ethereum;
      web3 = new Web3(window.ethereum);
      try {
        await window.ethereum.request({ method: "eth_requestAccounts" });
      } catch (error) {
        console.error("User denied account access");
      }
    } else if (window.web3) {
      App.web3Provider = window.web3.currentProvider;
      web3 = new Web3(window.web3.currentProvider);
    } else {
      console.log("No Ethereum provider detected. Install MetaMask.");
      App.web3Provider = new Web3.providers.HttpProvider("http://localhost:7545");
      web3 = new Web3(App.web3Provider);
    }
    return App.initContract();
  },

  initContract: function() {
    $.getJSON("Election.json", function(election) {
      App.contracts.Election = TruffleContract(election);
      App.contracts.Election.setProvider(App.web3Provider);

      App.listenForEvents(); 

      return App.render();
    });
  },

  listenForEvents: function() {
    App.contracts.Election.deployed().then(function(instance) {
      console.log("Listening for events...");

      instance.VotedEvent({}, { fromBlock: "latest" }).watch(function(error, event) {
        if (!error) {
          console.log("Vote event received:", event.returnValues);
          $("#eventLogs").prepend(`<li>Voter ${event.returnValues.voter} voted for candidate #${event.returnValues.candidateId}</li>`);
          App.render();
        }
      });

      instance.CandidateAdded({}, { fromBlock: "latest" }).watch(function(error, event) {
        if (!error) {
          console.log("New candidate added:", event.returnValues);
          $("#eventLogs").prepend(`<li>New candidate added: ${event.returnValues.name}</li>`);
          App.render();
        }
      });

      instance.CandidateRemoved({}, { fromBlock: "latest" }).watch(function(error, event) {
        if (!error) {
          console.log("Candidate removed:", event.returnValues);
          $("#eventLogs").prepend(`<li>Candidate #${event.returnValues.candidateId} was removed.</li>`);
          App.render();
        }
      });

      instance.ElectionEnded({}, { fromBlock: "latest" }).watch(function(error, event) {
        if (!error) {
          console.log("Election ended.");
          $("#eventLogs").prepend(`<li>Election has ended.</li>`);
          $("#electionStatus").text("Election is CLOSED").removeClass("text-danger").addClass("text-secondary");
          $("#endElectionBtn").hide();
          $('form').hide();
        }
      });

      instance.ElectionReset({}, { fromBlock: "latest" }).watch(function(error, event) {
        if (!error) {
          console.log("Election reset.");
          $("#eventLogs").prepend(`<li>Election has been reset.</li>`);
          App.render();
        }
      });
    });
  },

  render: function() {
    var electionInstance;
    var loader = $("#loader");
    var content = $("#content");

    loader.show();
    content.hide();

    web3.eth.getCoinbase(function(err, account) {
      if (err === null) {
        App.account = account;
        $("#accountAddress").html("Your Account: " + account);
      }
    });

    App.contracts.Election.deployed().then(function(instance) {
      electionInstance = instance;
      return electionInstance.candidatesCount();
    }).then(function(candidatesCount) {
      var candidatesResults = $("#candidatesResults");
      candidatesResults.empty();

      var candidatesSelect = $('#candidatesSelect');
      candidatesSelect.empty();

      for (var i = 1; i <= candidatesCount; i++) {
        electionInstance.candidates(i).then(function(candidate) {
          if(candidate[1] !== "") {
            var id = candidate[0];
            var name = candidate[1];
            var voteCount = candidate[2];

            var candidateTemplate = "<tr><th>" + id + "</th><td>" + name + "</td><td>" + voteCount + "</td></tr>"
            candidatesResults.append(candidateTemplate);

            var candidateOption = "<option value='" + id + "' >" + name + "</ option>"
            candidatesSelect.append(candidateOption);
          }
        });
      }
      return electionInstance.voters(App.account);
    }).then(function(hasVoted) {
      if (hasVoted) {
        $('form').hide();
      }
      loader.hide();
      content.show();
    }).catch(function(error) {
      console.warn(error);
    });
  },

  castVote: function() {
    if (App.isTransactionPending) {
        console.log("Предыдущая транзакция еще выполняется");
        return false;
    }
    
    var candidateId = $('#candidatesSelect').val();
    var voteButton = $('form button[type="submit"]');
    
    // Блокируем кнопку и устанавливаем флаг
    voteButton.prop('disabled', true);
    App.isTransactionPending = true;
    
    App.contracts.Election.deployed()
    .then(function(instance) {
        return instance.vote(candidateId, { from: App.account });
    })
    .then(function(result) {
        // Успешное голосование
        $("#content").hide();
        $("#loader").show();
        voteButton.text("Ваш голос учтен");
    })
    .catch(function(err) {
        console.error(err);
        // В случае ошибки разблокируем кнопку
        voteButton.prop('disabled', false);
        App.isTransactionPending = false;
        voteButton.text("Попробуйте снова");
    })
    .finally(function() {
        // Сбрасываем состояние только после успешной транзакции
        if (!App.isTransactionPending) {
            voteButton.prop('disabled', false);
            voteButton.text("Голосовать");
        }
    });
    
    return false; // Предотвращаем отправку формы
  },

  endElection: function() {
    if (App.isTransactionPending) return;
    
    var endButton = $('#endElectionBtn');
    endButton.prop('disabled', true);
    App.isTransactionPending = true;
    
    App.contracts.Election.deployed().then(function(instance) {
      return instance.endElection({ from: App.account });
    }).then(function(result) {
      console.log("Election ended.");
    }).catch(function(err) {
      console.error(err);
    }).finally(function() {
      endButton.prop('disabled', false);
      App.isTransactionPending = false;
    });
  },

  removeCandidate: function() {
    if (App.isTransactionPending) return;
    
    var removeButton = $('#removeCandidateBtn');
    var candidateId = $('#candidatesSelect').val();
    
    removeButton.prop('disabled', true);
    App.isTransactionPending = true;
    
    App.contracts.Election.deployed().then(function(instance) {
      return instance.removeCandidate(candidateId, { from: App.account });
    }).then(function(result) {
      console.log("Candidate removed.");
      App.render();
    }).catch(function(err) {
      console.error(err);
    }).finally(function() {
      removeButton.prop('disabled', false);
      App.isTransactionPending = false;
    });
  },

  registerVoter: function() {
    var voterAddress = $('#voterAddress').val();
    App.contracts.Election.deployed().then(function(instance) {
      return instance.registerVoter(voterAddress, { from: App.account });
    }).then(function(result) {
      console.log("Voter registered.");
    }).catch(function(err) {
      console.error(err);
    });
  },

  resetElection: function() {
    App.contracts.Election.deployed().then(function(instance) {
      return instance.resetElection({ from: App.account });
    }).then(function(result) {
      console.log("Election reset.");
    }).catch(function(err) {
      console.error(err);
    });
  }
};

$(function() {
  $(window).load(function() {
    App.init();
  });
});
