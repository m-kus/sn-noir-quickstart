# Creating a privacy preserving application on Starknet

In this tutorial, we will create a privacy preserving application on Starknet.  
We will use [Noir](https://noir-lang.org/) to write the circuit, [Cairo](https://cairo-lang.org/) for the smart contract, and finally [Garaga](https://garaga.gitbook.io/) for gluing everything together.

## Install dependencies

Follow the steps, or run the command below to install all the dependencies at once:

```bash
make install
```

### Step 1: Install Noir toolchain

```bash
curl -L noirup.dev | bash
noirup
```

### Step 2: Install Barretenberg

Barretenberg is a proving backend for Noir.

```bash
curl -L bbup.dev | bash
bbup
```

### Step 3: Install Scarb

Scarb is a Cairo package manager and compiler toolchain.

```bash
curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh -s -- -v 2.9.2
```

> [!NOTE]
> Scarb 2.9.2 is required to Garaga work correctly.

### Step 4: Install Starknet Foundry

Starknet Foundry is a smart contract development framework for Starknet.

```bash
curl -L https://raw.githubusercontent.com/foundry-rs/starknet-foundry/master/scripts/install.sh | sh
snfoundryup
```

### Step 5: Install Garaga

Garaga is a code generation tool, SDK, and Cairo library.  
It is shipped with a Python CLI:

```bash
pip install garaga
```

> [!NOTE]
> Python 3.10 is required to install Garaga.
> Use `pyenv` to manage your Python versions.

## Create and prove a circuit

### Step 6: Create a Noir project

```bash
nargo new circuit
cd circuit
nargo check
```

Fill the `Prover.toml` file with the inputs:

```toml
x = "1"
y = "2"
```

### Step 7: Prove the circuit

Execute the circuit to generate a witness:

```bash
nargo execute witness
```

Prove the circuit:

```bash
bb prove_ultra_keccak_honk -b ./target/circuit.json -w ./target/witness.gz -o ./target/proof
```

Generate a verifying key and verify the proof:

```bash
bb write_vk_ultra_keccak_honk -b ./target/circuit.json -o ./target/vk
bb verify_ultra_keccak_honk -k ./target/vk -p ./target/proof
```

## Create a Cairo smart contract

### Step 8: Generate Noir proof verifier

In the project folder, run:

```bash
garaga gen --system ultra_keccak_honk --vk circuit/target/vk.bin --project-name contract
cd contract
scarb build
```

### Step 9: Create Starknet account

Create a foundry config file named `snfoundry.toml` inside the `contract` folder:

```toml
[sncast.default]
account = "demo"
url = "https://starknet-sepolia.public.blastapi.io/rpc/v0_7"
```

Create a Starknet account:

```bash
sncast account create --type oz --name demo
```

### Step 10: Send some money to the generated address

Go to https://starknet-faucet.vercel.app/ and paste the address of the account you created.  
Use STRK as the fee token.

> [!NOTE]
> You might need to prepend a zero to your account in case of an error.
> Ex. `0x123...` -> `0x0123...`

### Step 11: Deploy the account contract

On Starknet all accounts are contracts, even your wallet, so you need to deploy an account contract to interact with your application.

```bash
sncast account deploy --fee-token strk --name demo
```

### Step 12: Initialize Garaga environment

Create a `.secrets` file in the `contract` folder and add the following variables:

```
SEPOLIA_RPC_URL="https://free-rpc.nethermind.io/sepolia-juno"
SEPOLIA_ACCOUNT_PRIVATE_KEY=<your_private_key>
SEPOLIA_ACCOUNT_ADDRESS=<your_address>
```

The values can be obtained by running:

```bash
sncast account list -p
```

### Step 13: Deploy the verifier contract

First we need to declare the contract ("upload it's code hash to the network"):

```bash
garaga declare --fee strk
```

Then we can instantiate it (change class-hash according to the output on the previous step):

```bash
garaga deploy --fee strk --class-hash 0x16208fd89b588750d32a93c1c5066fe41489b21d62632051002a2fda15b0bd1
```

## Verify the proof on Starknet

### Step 14: Invoke the verifier contract

```bash
garaga verify-onchain --system ultra_keccak_honk --contract-address 0x2452c8fabb9b6fdf9479526de3dea401a70c290e400511d2291b1be4c355ad7 --proof ../circuit/target/proof --vk ../circuit/target/vk --fee strk
```
