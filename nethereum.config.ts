const config : NethereumConfig = 
{
    projectName: "Cryptopia.NethereumContracts.csproj",
    projectPath: "./.nethereum",
    namespace: "Cryptopia.NethereumContracts",
    lang: 0, // CSharp 0, Vb.Net 1, FSharp 3
    autoCodeGen: true,
    contracts: [
        "CryptopiaInventories",
        "Whitelist",
        "CryptopiaToken",
        "CryptopiaAccountRegister",
        "CryptopiaAssetRegister",
        "CryptopiaShipToken", 
        "CryptopiaCrafting",
        "CryptopiaPlayerRegister", 
        "CryptopiaToolToken", 
        "CryptopiaTitleDeedToken", 
        "CryptopiaMaps", 
        "CryptopiaMapsExtensions", 
        "CryptopiaTitleDeedToken",
        "CryptopiaQuestToken", 
        "CryptopiaQuests", 
        "CryptopiaResourceGathering", 
        "CryptopiaAssetToken", 
        "CryptopiaNavalBattleMechanics", 
        "CryptopiaPirateMechanics"
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