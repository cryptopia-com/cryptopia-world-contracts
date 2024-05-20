## Scripts

Port:
npx hardhat run --network localhost ./scripts/port.ts

Deploy:
npx hardhat run --network localhost ./scripts/deploy.ts

Verify:
npx hardhat run --network skaleNebulaTestnet ./scripts/verify.ts

Tools: 
npx hardhat run --network localhost ./scripts/tools/tools.publish.ts

Quests:
npx hardhat run --network localhost ./scripts/quests/items.publish.ts
npx hardhat run --network localhost ./scripts/quests/quests.publish.ts

Ships:
npx hardhat run --network skaleNebulaTestnet ./scripts/ships/skins.publish.ts

Crafting:
npx hardhat run --network localhost ./scripts/crafting/recipes.publish.ts

Maps:
npx hardhat run --network localhost ./scripts/maps/maps.publish.ts

Node:
npx hardhat node
npx hardhat setAutomine --network localhost --state true
npx hardhat setIntervalMining --network localhost --interval 5000
npx hardhat fundLocalhost --network localhost --address 0xD90fE41BE6921Df2dCC481c4A7347ed1dc80a504