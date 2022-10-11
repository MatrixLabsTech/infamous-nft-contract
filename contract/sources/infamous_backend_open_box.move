module infamous::infamous_backend_open_box {

     use std::bcs;
     use std::signer;
     use std::string::{Self, String};
     use std::error;

     
     use aptos_token::token;

     use infamous::infamous_upgrade_level;
     use infamous::infamous_manager_cap;
     use infamous::infamous_nft;
     use infamous::infamous_backend_auth;
     
    const ACCOUNT_MUSTBE_AUTHED: u64 = 1;
    const LEVEL_MUST_GREATER_THAN_THREE: u64 = 2;

    const OPEN_LEVEL: u64 = 3;


     public entry fun open_box(
        sender: &signer,
        creator: address, collection: String, name: String,
        background: String, clothing: String, ear: String, eyes: String, 
        eyebrow: String, face_accessories: String, hear: String, mouth: String, 
        neck: String, tatto: String) {
        let sender_addr = signer::address_of(sender);
        
        assert!(infamous_backend_auth::has_capability(sender_addr), error::unauthenticated(ACCOUNT_MUSTBE_AUTHED));

        let token_id = infamous_nft::resolve_token_id(creator, collection, name);
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        let level = infamous_upgrade_level::get_token_level(manager_addr, token_id);
        assert!(level >= OPEN_LEVEL, error::invalid_argument(LEVEL_MUST_GREATER_THAN_THREE));


        let token_data_id = token::create_token_data_id(creator, collection, name);
        let keys = vector<String>[string::utf8(b"background"), string::utf8(b"clothing"), string::utf8(b"ear"), string::utf8(b"eyes"), 
        string::utf8(b"eyebrow"), string::utf8(b"face_accessories"), string::utf8(b"hear"), string::utf8(b"mouth"), 
        string::utf8(b"neck"), string::utf8(b"tatto"),];
        let values = vector<vector<u8>>[bcs::to_bytes<String>(&background), bcs::to_bytes<String>(&clothing), bcs::to_bytes<String>(&ear), bcs::to_bytes<String>(&eyes),
        bcs::to_bytes<String>(&eyebrow), bcs::to_bytes<String>(&face_accessories), bcs::to_bytes<String>(&hear), bcs::to_bytes<String>(&mouth),
        bcs::to_bytes<String>(&neck), bcs::to_bytes<String>(&tatto),];
        let types = vector<String>[string::utf8(b"0x1::string::String"), string::utf8(b"0x1::string::String"), string::utf8(b"0x1::string::String"), string::utf8(b"0x1::string::String"), 
        string::utf8(b"0x1::string::String"), string::utf8(b"0x1::string::String"), string::utf8(b"0x1::string::String"), string::utf8(b"0x1::string::String"), 
        string::utf8(b"0x1::string::String"), string::utf8(b"0x1::string::String"), ];

        token::mutate_tokendata_property(&manager_signer,
        token_data_id,
        keys, values, types
        );
     }
}