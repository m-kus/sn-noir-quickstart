install-noir:
	curl -L https://raw.githubusercontent.com/noir-lang/noirup/refs/heads/main/install | bash
	noirup

install-barretenberg:
	curl -L https://raw.githubusercontent.com/AztecProtocol/aztec-packages/refs/heads/master/barretenberg/bbup/install | bash
	bbup

install-scarb:
	curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh -s -- -v 2.9.2

install-snfoundry:
	curl -L https://raw.githubusercontent.com/foundry-rs/starknet-foundry/master/scripts/install.sh | sh
	snfoundryup

install-garaga:
	pip install garaga

install: install-noir install-barretenberg install-scarb install-snfoundry install-garaga

build-circuit:
	cd circuit && nargo build

exec-circuit:
	cd circuit && nargo execute witness

prove-circuit:
	bb prove_ultra_keccak_honk -b ./circuit/target/circuit.json -w ./circuit/target/witness.gz -o ./circuit/target/proof

gen-vk:
	bb write_vk_ultra_keccak_honk -b ./circuit/target/circuit.json -o ./circuit/target/vk

gen-contract:
	garaga gen --system ultra_keccak_honk --vk circuit/target/vk --project-name contract

build-contract:
	cd contract && scarb build

create-account:
	cd contract && sncast account create --type oz --name demo

deploy-account:
	cd contract && sncast account deploy --fee-token strk --name demo

declare-contract:
	cd contract && garaga declare --fee strk

deploy-contract:
	cd contract && garaga deploy --fee strk --class-hash 0x16208fd89b588750d32a93c1c5066fe41489b21d62632051002a2fda15b0bd1

invoke-contract:
	cd contract && \
		garaga verify-onchain \
			--system ultra_keccak_honk \
			--contract-address 0x2452c8fabb9b6fdf9479526de3dea401a70c290e400511d2291b1be4c355ad7 \
			--proof ../circuit/target/proof \
			--vk ../circuit/target/vk \
			--fee strk
