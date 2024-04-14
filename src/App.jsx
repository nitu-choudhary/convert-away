import React, { useState } from 'react';
import { ethers } from 'ethers';
import {Form, Button, Card, Image} from 'react-bootstrap';
import {abi} from './contractABI';

const contractAddress = import.meta.env.VITE_CONTRACT_ADDRESS;

function App() {
  // get stored price
  const [storedPrice, setStoredPrice] = useState('');
  // to select the pair from available pairs to send to the smart contract
  const [item, setItem] = useState({pairs:''});

  const { pairs } = item;

  let feedId = 1;

  const contractABI = abi;

  async function requestAccount() {
    await window.ethereum.request({ method: 'eth_requestAccounts' })
  }

  const getPair = async () => {
    switch (pairs) {
      case 'BTC/USD':
        feedId = 1;
        break;
      case 'ETH/USD':
        feedId = 2;
        break;
      case 'LINK/USD':
        feedId = 3;
        break;
      case 'BTC/ETH':
        feedId = 4;
        break;
      default:
        return;
    }

  if (typeof window.ethereum !== 'undefined') {
    await requestAccount();
    const provider = new ethers.providers.Web3Provider(window.ethereum);
    const signer = provider.getSigner();
    const contract = new ethers.Contract(contractAddress, contractABI, signer);
    // call the updatePrice function from the smart contract
    await contract.updatePrice(feedId);

    try {
      const price = await contract.getLastFetchedPrice(feedId);
      if(feedId!==4){
        setStoredPrice('$' + parseInt(price)/100000000);
      } else {
        setStoredPrice(parseInt(price)/(10**18) + ' ETH');
      }
    } catch (error) {
      console.error(error);
    }
  }
}

// handle the form input
const handleInputChange = e => {
  setStoredPrice('');
  setItem((prevState) => ({
    ...prevState,
    pairs : e.target.value,
  }));
};

const handleSubmit = (e) => {
  e.preventDefault();
}

return (
  <div className="container">
    <Image 
      src='https://seeklogo.com/images/C/chainlink-logo-B072B6B9FE-seeklogo.com.png' 
      alt="Chainlink Logo" 
      width={200} 
      height={200} 
      fluid 
      className='mt-5'
    />
    <hr></hr>
    <div>
      <Card 
        style={{ width: '32rem' }} 
        className='mt-5 shadow bg-body rounded'>
        <Card.Header as='h5'>Conversion Pair</Card.Header>
        <Card.Body>
          {' '}
          <div className='col'>
            <form onSubmit={handleSubmit}>
              <Form.Group controlId='pairs'>
              <Form.Check
                type='radio'
                aria-label='radio-1'
                label='BTC/USD'
                value='BTC/USD'
                onChange={handleInputChange}
                checked={pairs === 'BTC/USD'}
              />
                <Form.Check
                  type='radio'
                  aria-label='radio-2'
                  label='ETH/USD'
                  value='ETH/USD'
                  onChange={handleInputChange}
                  checked={pairs === 'ETH/USD'}
                />
                <Form.Check
                  type='radio'
                  aria-label='radio-3'
                  label='LINK/USD'
                  value='LINK/USD'
                  onChange={handleInputChange}
                  checked={pairs === 'LINK/USD'}
                />
                <Form.Check
                  type='radio'
                  aria-label='radio-4'
                  label='BTC/ETH'
                  value='BTC/ETH'
                  onChange={handleInputChange}
                  checked={pairs === 'BTC/ETH'}
                />
              </Form.Group>
            </form>
            <div className='mt-5'>
              <Button variant='outline-primary' size='sm' 
              onClick={getPair}
              >
                Get Answer From the Price Oracle
              </Button>
            </div>
          </div>
        </Card.Body>
      </Card>
      <div>
        <Card style={{ width: '32rem' }} className='mt-5 shadow bg-body rounded'>
          <Card.Header as='h5'>Answer</Card.Header>
          <Card.Body>
              <h5>{pairs} --{'>'} {storedPrice}</h5>
          </Card.Body>
        </Card>
      </div>
    </div>
  </div>
);
}

export default App