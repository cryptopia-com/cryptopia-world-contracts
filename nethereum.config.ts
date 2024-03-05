const config : NethereumConfig = 
{
    projectName: "Cryptopia.NethereumContracts.csproj",
    projectPath: "./.nethereum",
    namespace: "Cryptopia.NethereumContracts",
    lang: 0, // CSharp 0, Vb.Net 1, FSharp 3
    autoCodeGen: true,
    contracts: [
        "CryptopiaEntry",
        "CryptopiaERC20",
        "CryptopiaERC721",
        "CryptopiaAccount",
        "CryptopiaAccountRegister",
        "CryptopiaPlayerRegister", 
        "CryptopiaAvatarRegister",
        "CryptopiaAssetRegister",
        "CryptopiaToken",
        "CryptopiaAssetToken", 
        "CryptopiaShipToken", 
        "CryptopiaToolToken", 
        "CryptopiaTitleDeedToken", 
        "CryptopiaQuestToken", 
        "CryptopiaMaps",
        "CryptopiaMapsExtensions", 
        "CryptopiaInventories",
        "CryptopiaQuests", 
        "CryptopiaCrafting",
        "CryptopiaResourceGathering", 
        "CryptopiaPirateMechanics",
        "CryptopiaNavalBattleMechanics"
    ]
}

export default config;

export interface NethereumConfig 
{
    projectName: string;
    projectPath: string;
    namespace: string;
    lang: number;
    autoCodeGen: boolean;
    contracts: string[];
}