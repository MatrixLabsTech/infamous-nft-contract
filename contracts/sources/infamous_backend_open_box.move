/// This module provides open box -> change the properties of Token.
module infamous::infamous_backend_open_box {

     use std::bcs;
     use std::signer;
     use std::string::{String, utf8};
     use std::error;


     use aptos_framework::timestamp;
     use aptos_std::table::{Self, Table};
     
     use aptos_token::token::{Self, TokenDataId, TokenId};

     use infamous::infamous_common;
     use infamous::infamous_manager_cap;
     use infamous::infamous_nft;
     use infamous::infamous_backend_auth;
     use infamous::infamous_weapon_nft;
     use infamous::infamous_weapon_status;
     
    const EACCOUNT_MUSTBE_AUTHED: u64 = 1;
    const EOPEN_MUST_BE_FIVE_DAYS_AFTER_MINT: u64 = 2;
    const EBOX_ALREADY_OPENED: u64 = 3;

    const OPEN_TIME_GAP: u64 = 60;


    struct OpenBoxStatus has key {
        open_status: Table<TokenId, bool>
    }

    fun initialize_open_box_status(account: &signer) {
        let account_addr = signer::address_of(account);
        if(!exists<OpenBoxStatus>(account_addr)) {
            move_to(
                account,
                OpenBoxStatus {
                    open_status: table::new<TokenId, bool>(),
                }
            );
        }
    }


    public entry fun open_box(sender: &signer,
        name: String,
        background: String, clothing: String, earrings: String, eyebrows: String,
        face_accessories: String, eyes: String, hair: String,  
        mouth: String, necklace: String, tattoo: String,  gender: String,
        weapon: String, tier: String, grade: String, attributes: String,) acquires OpenBoxStatus {

        

        let sender_addr = signer::address_of(sender);
        assert!(infamous_backend_auth::has_capability(sender_addr), error::unauthenticated(EACCOUNT_MUSTBE_AUTHED));

        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        initialize_open_box_status(&manager_signer);

        
        // resolve token id
        let creator = manager_addr;
        let collection = infamous_common::infamous_collection_name();
        let token_id = infamous_nft::resolve_token_id(creator, collection, name);

        // check owner
        // assert!(token::balance_of(owner_addr, token_id) == 1, error::invalid_argument(TOKEN_NOT_OWNED_BY_OWNER_ADDR));
        assert!(!is_box__opened(token_id), error::invalid_state(EBOX_ALREADY_OPENED));

        // check now - mint time > 180s
        let token_mint_time = infamous_nft::get_token_mint_time(token_id);
        assert!(timestamp::now_seconds() - token_mint_time >= OPEN_TIME_GAP, error::invalid_argument(EOPEN_MUST_BE_FIVE_DAYS_AFTER_MINT));

        let weapon_token_id = infamous_weapon_nft::airdrop(manager_addr, weapon, tier, grade, attributes);
        let token_data_id = token::create_token_data_id(creator, collection, name);
        infamous_nft::set_token_gender(token_data_id, gender);
        mutate_token_properties(manager_signer, token_data_id, background, clothing, earrings, eyebrows, face_accessories, eyes, hair, mouth, necklace, tattoo, weapon);
        let (_creator, _collection, weapon_token_name, _property_version) = token::get_token_id_fields(&weapon_token_id);
        infamous_weapon_status::update_token__weapon_token_name(token_id, weapon_token_name);
        
        infamous_nft::update_token_uri_with_known_properties(token_data_id, background, clothing, earrings, eyebrows, face_accessories, eyes, hair, mouth, necklace, tattoo, weapon, grade, gender,);
        update_box_opened(token_id);
    }

     fun mutate_token_properties(manager_signer: signer, 
        token_data_id: TokenDataId, 
        background: String, clothing: String, earrings: String, eyebrows: String,
        face_accessories: String, eyes: String, hair: String,  
        mouth: String, necklace: String, tattoo: String, 
        weapon: String) {
        
        let keys = vector<String>[utf8(b"background"), utf8(b"clothing"), utf8(b"earrings"), utf8(b"eyebrows"), 
        utf8(b"face-accessories"), utf8(b"eyes"), utf8(b"hair"), 
        utf8(b"mouth"), utf8(b"necklace"), utf8(b"tattoo"), 
        utf8(b"weapon"), ];
        let values = vector<vector<u8>>[bcs::to_bytes<String>(&background), bcs::to_bytes<String>(&clothing), bcs::to_bytes<String>(&earrings), bcs::to_bytes<String>(&eyebrows),
        bcs::to_bytes<String>(&face_accessories), bcs::to_bytes<String>(&eyes), bcs::to_bytes<String>(&hair), 
        bcs::to_bytes<String>(&mouth), bcs::to_bytes<String>(&necklace), bcs::to_bytes<String>(&tattoo), 
        bcs::to_bytes<String>(&weapon), ];
        let types = vector<String>[utf8(b"0x1::string::String"), utf8(b"0x1::string::String"), utf8(b"0x1::string::String"), utf8(b"0x1::string::String"), 
        utf8(b"0x1::string::String"), utf8(b"0x1::string::String"), utf8(b"0x1::string::String"), 
        utf8(b"0x1::string::String"), utf8(b"0x1::string::String"), utf8(b"0x1::string::String"), 
        utf8(b"0x1::string::String"),];

        token::mutate_tokendata_property(&manager_signer,
        token_data_id,
        keys, values, types
        );



     }

     
    public fun is_box__opened(token_id: TokenId): bool acquires OpenBoxStatus { 
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        let box_opend = false;
        if(exists<OpenBoxStatus>(manager_addr)) {
            let open_status = &borrow_global<OpenBoxStatus>(manager_addr).open_status;
            box_opend = table::contains(open_status, token_id);
        };
        box_opend
    }

     
    fun update_box_opened(token_id: TokenId) acquires OpenBoxStatus { 
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);

        initialize_open_box_status(&manager_signer);

        let open_status = &mut borrow_global_mut<OpenBoxStatus>(manager_addr).open_status;
        if(!table::contains(open_status, token_id)) {
            table::add(open_status, token_id, true);
        };
    }

       
    #[test(framework = @0x1, user = @infamous, receiver = @0xBB)]
    public fun open_box_test(user: &signer, receiver: &signer, framework: &signer) acquires OpenBoxStatus { 

        use aptos_framework::account; 
        use aptos_framework::timestamp;
        use infamous::infamous_nft;
        use infamous::infamous_properties_url_encode_map;
        use infamous::infamous_weapon_nft;

        timestamp::set_time_has_started_for_testing(framework);


        let user_addr = signer::address_of(user);
        account::create_account_for_test(user_addr);
        
        infamous_manager_cap::initialize(user);
        infamous_nft::initialize(user);
        infamous_weapon_nft::initialize(user);
        infamous_properties_url_encode_map::initialize(user);

        let receiver_addr = signer::address_of(receiver);
        account::create_account_for_test(receiver_addr);
        infamous_nft::mint(receiver, 3);

        
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        let collection_name = infamous_common::infamous_collection_name();
        let base_token_name = infamous_common::infamous_base_token_name();
        let token_index_1_name = infamous_common::append_num(base_token_name, 1);

        let token_id = infamous_nft::resolve_token_id(manager_addr, collection_name, token_index_1_name);
        assert!(token::balance_of(receiver_addr, token_id) == 1, 1);

    
        timestamp::fast_forward_seconds(1000);

        let background = utf8(b"blue");
        let clothing = utf8(b"hoodie");
        let earrings = utf8(b"null");
        let eyebrows = utf8(b"extended eyebrowss");
        let face_accessories = utf8(b"null");
        let eyes = utf8(b"black eyes");
        let hair = utf8(b"bob cut 1 (navy blue)");
        let mouth = utf8(b"closed");
        let necklace = utf8(b"null");
        let tattoo = utf8(b"null");
        let gender = utf8(b"female");
        let weapon = utf8(b"dagger");
        let tier = utf8(b"1");
        let grade = utf8(b"iron");
        let attributes = utf8(b"iron");

         open_box(user,
         token_index_1_name,
         background, clothing, earrings, eyebrows, 
         face_accessories, eyes, hair, mouth,
         necklace, tattoo, gender,
         weapon, tier, grade, attributes
         );


    }

    
       
}