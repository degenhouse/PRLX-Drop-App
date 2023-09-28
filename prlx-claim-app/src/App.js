// Cheyne Basic Dapp Claim
import React, { useState, useEffect } from 'react';
import Web3 from 'web3';
import TokenDropContract from './contracts/TokenDrop.json';

const DropDappComponent = () => {
  const [web3, setWeb3] = useState(null);
  const [contract, setContract] = useState(null);
  const [accounts, setAccounts] = useState([]);
  const [whitelistFile, setWhitelistFile] = useState(null);

  const handleWhitelistFileChange = (event) => {
    const file = event.target.files[0];
    const reader = new FileReader();
    reader.onload = (e) => {
      setWhitelistFile(e.target.result);
    };
    reader.readAsText(file);
  };

  const handleDistributeTokens = async () => {
    if (!whitelistFile) {
      console.error('Please upload a whitelist file.');
      return;
    }

    try {
      const lines = whitelistFile.split('\n');
      const addresses = [];
      const amounts = [];

      lines.forEach((line) => {
        const [address, amount] = line.split(',');
        addresses.push(address.trim());
        amounts.push(parseInt(amount.trim(), 10));
      });

      await contract.methods.addToWhitelist(addresses, amounts).send({ from: accounts[0] });
      console.log('Whitelist updated successfully');
    } catch (error) {
      console.error('Error updating whitelist', error);
    }
  };

  const handleClaimTokens = async () => {
    try {
      await contract.methods.claimTokens().send({ from: accounts[0] });
      console.log('Tokens claimed successfully');
    } catch (error) {
      console.error('Error claiming tokens', error);
    }
  };

  const initializeWeb3 = async () => {
    if (window.ethereum) {
      try {
        const web3Instance = new Web3(window.ethereum);
        await window.ethereum.enable();
        setWeb3(web3Instance);

        const accounts = await web3Instance.eth.getAccounts();
        setAccounts(accounts);

        const networkId = await web3Instance.eth.net.getId();
        const deployedNetwork = TokenDropContract.networks[networkId];
        const contractInstance = new web3Instance.eth.Contract(
          TokenDropContract.abi,
          deployedNetwork && deployedNetwork.address
        );
        setContract(contractInstance);
      } catch (error) {
        console.error('Error connecting to Binance Smart Chain', error);
      }
    } else {
      console.error('Please install MetaMask extension');
    }
  };

  useEffect(() => {
    initializeWeb3();
  }, []);

  return (
    <div>
      <h1>PRLX Token Claim </h1>
      <button onClick={handleClaimTokens}>Claim Tokens</button>
    </div>
  );
};

export default DropDappComponent;
