install-noir:
	curl -L https://raw.githubusercontent.com/noir-lang/noirup/refs/heads/main/install | bash
	noirup --version 1.0.0-beta.1

install-barretenberg:
	curl -L https://raw.githubusercontent.com/AztecProtocol/aztec-packages/refs/heads/master/barretenberg/bbup/install | bash
	bbup --version 0.67.0

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
	cd contract && garaga deploy --fee strk --class-hash 0x62412c03a6d8f5d1b721757a67e5e2d092ae0bbbdb487eb1c7c598835324a76

invoke-contract:
	cd contract && \
		garaga verify-onchain \
			--system ultra_keccak_honk \
			--contract-address 0x52691054da2ae92e7dd55afe4201adc6da412c97539f0f5b8687d069581165b \
			--proof ../circuit/target/proof \
			--vk ../circuit/target/vk \
			--fee strk
