module infamous::infamous_backend_open_box {

     use std::bcs;
     use std::signer;
     use std::string::{Self, String, utf8};
     use std::error;


     
     use aptos_token::token;
     use aptos_token::property_map::{Self, PropertyMap};

     use infamous::infamous_common;
     use infamous::infamous_upgrade_level;
     use infamous::infamous_manager_cap;
     use infamous::infamous_nft;
     use infamous::infamous_backend_auth;
     use infamous::infamous_weapon_nft;
     use infamous::infamous_weapon_wear;
     
    const ACCOUNT_MUSTBE_AUTHED: u64 = 1;
    const LEVEL_MUST_GREATER_THAN_THREE: u64 = 2;

    const OPEN_LEVEL: u64 = 3;


     public entry fun open_box(
        sender: &signer,
        name: String,

        background: String, clothing: String, ear: String, eyes: String, 
        eyebrow: String, accessories: String, hear: String, mouth: String,  
        neck: String, tatto: String, gender: String, 
        weapon: String, material: String, level: String) { 
        
        let sender_addr = signer::address_of(sender);
        assert!(infamous_backend_auth::has_capability(sender_addr), error::unauthenticated(ACCOUNT_MUSTBE_AUTHED));

        
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);

        let creator = manager_addr;
        let collection = infamous_common::infamous_collection_name();

        let token_id = infamous_nft::resolve_token_id(creator, collection, name);
        let token_level = infamous_upgrade_level::get_token_level(manager_addr, token_id);
        assert!(token_level >= OPEN_LEVEL, error::invalid_argument(LEVEL_MUST_GREATER_THAN_THREE));


        let token_data_id = token::create_token_data_id(creator, collection, name);
        let keys = vector<String>[utf8(b"background"), utf8(b"clothing"), utf8(b"ear"), utf8(b"eyes"), 
        utf8(b"eyebrow"), utf8(b"accessories"), utf8(b"hear"), utf8(b"mouth"), 
        utf8(b"neck"), utf8(b"tatto"), utf8(b"gender"), ];
        let values = vector<vector<u8>>[bcs::to_bytes<String>(&background), bcs::to_bytes<String>(&clothing), bcs::to_bytes<String>(&ear), bcs::to_bytes<String>(&eyes),
        bcs::to_bytes<String>(&eyebrow), bcs::to_bytes<String>(&accessories), bcs::to_bytes<String>(&hear), bcs::to_bytes<String>(&mouth),
        bcs::to_bytes<String>(&neck), bcs::to_bytes<String>(&tatto), bcs::to_bytes<String>(&gender), ];
        let types = vector<String>[utf8(b"0x1::string::String"), utf8(b"0x1::string::String"), utf8(b"0x1::string::String"), utf8(b"0x1::string::String"), 
        utf8(b"0x1::string::String"), utf8(b"0x1::string::String"), utf8(b"0x1::string::String"), utf8(b"0x1::string::String"), 
        utf8(b"0x1::string::String"), utf8(b"0x1::string::String"), utf8(b"0x1::string::String"), ];

        token::mutate_tokendata_property(&manager_signer,
        token_data_id,
        keys, values, types
        );


        let weapon_token_name = infamous_weapon_nft::do_airdrop(sender, manager_addr, weapon, material, level);
        infamous_weapon_wear::wear_weapon(&manager_signer, name, weapon_token_name);

     }



     fun append_property(properties_string: &mut String, properties: PropertyMap, property_key: String) {
        if(property_map::contains_key(&properties, &property_key)) {
            string::append(properties_string, property_map::read_string(&properties, &property_key));
        };
     }


       
    #[test(framework = @0x1, user = @infamous, receiver = @0xBB)]
    public fun open_box_test(user: &signer, receiver: &signer, framework: &signer) { 

        use aptos_framework::account; 
        use aptos_framework::timestamp;
        use infamous::infamous_stake;
        use infamous::infamous_nft;
        use infamous::infamous_weapon_nft;
        use infamous::infamous_upgrade_level;
        use aptos_std::debug;

        timestamp::set_time_has_started_for_testing(framework);


        let user_addr = signer::address_of(user);
        account::create_account_for_test(user_addr);
        
        infamous_manager_cap::initialize(user);
        infamous_nft::initialize(user);
        infamous_weapon_nft::initialize(user);

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
        infamous_stake::stake_infamous_nft_script(receiver, token_index_1_name);

        let time = infamous_stake::get_available_time(token_id);
        debug::print<u64>(&time);

        timestamp::fast_forward_seconds(1000);
        let time1 = infamous_stake::get_available_time(token_id);
        debug::print<u64>(&time1);

        infamous_upgrade_level::upgrade(token_index_1_name);
        let after = infamous_upgrade_level::get_token_level(manager_addr, token_id);
        debug::print<u64>(&222222);
        debug::print<u64>(&after);
        debug::print<u64>(&222222);



        let background = utf8(b"blue");
        let clothing = utf8(b"dungarees");
        let ear = utf8(b"hoop earrings");
        let eyes = utf8(b"straight");
        let eyebrow = utf8(b"band-aid");
        let accessories = utf8(b"white");
        let hear = utf8(b"high");
        let mouth = utf8(b"choker");
        let neck = utf8(b"fox mask");
        let tatto = utf8(b"danger");
        let gender = utf8(b"male");
        let weapon = utf8(b"danger");

        let material = utf8(b"ssss");
        let level = utf8(b"3");

         open_box(user, 
         token_index_1_name,
         background, clothing, ear, eyes,
         eyebrow, accessories, hear, mouth,
         neck, tatto, gender,
         weapon, material, level
         );


    }

    
       
}