/// This module provides open box -> change the properties of Token.
/// InfamousBackendOpenBox used to mutate infamous nft's property by authed account 
module infamous::infamous_backend_open_box {

    use std::signer;
    use std::string::{String, utf8};
    use std::error;
    use std::vector;
    use aptos_framework::timestamp;
    use aptos_std::table::{Self, Table};
    use aptos_token::token::{Self, TokenId};
    use infamous::infamous_common;
    use infamous::infamous_manager_cap;
    use infamous::infamous_nft;
    use infamous::infamous_backend_auth;
    use infamous::infamous_weapon_nft;
    use infamous::infamous_link_status;
    use infamous::infamous_accessory_nft;
    
    //
    // Errors
    //
    /// Error when some fun need backend authed, but called with no authed account.
    const EACCOUNT_MUSTBE_AUTHED: u64 = 1;
    /// Error when call open_box in five days after minted
    const EOPEN_MUST_BE_FIVE_DAYS_AFTER_MINT: u64 = 2;
    /// Error when call open_box multi times
    const EBOX_ALREADY_OPENED: u64 = 3;



     
    //
    // Contants
    //
    // open time after minted (second)
    /// @Todo change to 432000(5 days) when prod
    const OPEN_TIME_GAP_FIVE_DAYS: u64 = 1;


    struct OpenBoxStatus has key {
        // store the token open status
        open_status: Table<TokenId, bool>
    }

    /// open box, mutate infamous nft with certain properties. airdrop weapon. airdrop accessory.
    public entry fun open_box(sender: &signer,
        name: String,
        background: String, 
        clothing: String, clothing_attributes: String, 
        earrings: String, earrings_attributes: String, eyebrows: String,
        face_accessory: String, face_accessory_attributes: String, 
        eyes: String, hair: String,  
        mouth: String, mouth_attributes: String,
        neck: String, neck_attributes: String, 
        tattoo: String, tattoo_attributes: String, gender: String,
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

        // check now - mint time > five days
        let token_mint_time = infamous_nft::get_token_mint_time(token_id);
        assert!(timestamp::now_seconds() - token_mint_time >= OPEN_TIME_GAP_FIVE_DAYS, error::invalid_argument(EOPEN_MUST_BE_FIVE_DAYS_AFTER_MINT));


        // airdrop weapon
        let weapon_token_id = infamous_weapon_nft::airdrop(manager_addr, weapon, tier, grade, attributes);
        
        // update token bind weapon token name
        infamous_link_status::update_token__weapon_token_id(token_id, weapon_token_id);


        // airdrop accessory
        let accessory_kinds = vector::empty<String>();
        let accessory_values = vector::empty<TokenId>();
        airdrop_accessory(&mut accessory_kinds, &mut accessory_values, 
        manager_addr,
        tattoo, tattoo_attributes,
        clothing, clothing_attributes,  face_accessory, face_accessory_attributes,
        earrings, earrings_attributes,  neck, neck_attributes,  mouth, mouth_attributes, gender);
        infamous_link_status::update_token__accessory_token_ids(token_id, accessory_kinds, accessory_values,);
       
        
        // update token properties
        let token_data_id = token::create_token_data_id(creator, collection, name);
        infamous_nft::mutate_token_properties(&manager_signer, token_data_id, background, clothing, earrings, eyebrows, face_accessory, eyes, hair, mouth, neck, tattoo, weapon, grade, gender,);
        update_box_opened(token_id);
    }

    /// check box opened
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

    /// airdrop need accessory
    fun airdrop_accessory(
        accessory_kinds: &mut vector<String>,
        accessory_values: &mut vector<TokenId>,
        manager_addr: address,
        tattoo: String, tattoo_attributes: String,
        clothing: String, clothing_attributes: String,
        face_accessory: String, face_accessory_attributes: String,
        earrings: String, earrings_attributes: String,
        neck: String, neck_attributes: String,
        mouth: String, mouth_attributes: String,
        gender: String,
    ) {
        let empty_accessory = utf8(b"null");
        if (tattoo != empty_accessory) {
            let kind = utf8(b"tattoo");
            let token_id = infamous_accessory_nft::airdrop(manager_addr, tattoo, kind, gender, tattoo_attributes);
            vector::push_back(accessory_kinds, kind);
            vector::push_back(accessory_values, token_id);
        };
        if (clothing != empty_accessory) {
            let kind = utf8(b"clothing");
            let token_id = infamous_accessory_nft::airdrop(manager_addr, clothing, kind, gender, clothing_attributes);
            vector::push_back(accessory_kinds, kind);
            vector::push_back(accessory_values, token_id);
        };
        if (face_accessory != empty_accessory) {
            let kind = utf8(b"face-accessory");
            let token_id = infamous_accessory_nft::airdrop(manager_addr, face_accessory, kind, gender, face_accessory_attributes);
            vector::push_back(accessory_kinds, kind);
            vector::push_back(accessory_values, token_id);
        };
        if (earrings != empty_accessory) {
            let kind = utf8(b"earrings");
            let token_id = infamous_accessory_nft::airdrop(manager_addr, earrings, kind, gender, earrings_attributes);
            vector::push_back(accessory_kinds, kind);
            vector::push_back(accessory_values, token_id);
        };
        if (neck != empty_accessory) {
            let kind = utf8(b"neck");
            let token_id = infamous_accessory_nft::airdrop(manager_addr, neck, kind, gender, neck_attributes);
            vector::push_back(accessory_kinds, kind);
            vector::push_back(accessory_values, token_id);
        };
        if (mouth != empty_accessory) {
            let kind = utf8(b"mouth");
            let token_id = infamous_accessory_nft::airdrop(manager_addr, mouth, kind, gender, mouth_attributes);
            vector::push_back(accessory_kinds, kind);
            vector::push_back(accessory_values, token_id);
        };
    }
     
    /// update infamous token open status
    fun update_box_opened(token_id: TokenId) acquires OpenBoxStatus { 
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);

        initialize_open_box_status(&manager_signer);

        let open_status = &mut borrow_global_mut<OpenBoxStatus>(manager_addr).open_status;
        if(!table::contains(open_status, token_id)) {
            table::add(open_status, token_id, true);
        };
    }

    /// init openboxstatus store to account
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


    #[test(framework = @0x1, user = @infamous, receiver = @0xBB)]
    public fun open_box_test(user: &signer, receiver: &signer, framework: &signer) acquires OpenBoxStatus { 

        use aptos_framework::account; 
        use aptos_framework::timestamp;
        use infamous::infamous_nft;
        use infamous::infamous_properties_url_encode_map;
        use infamous::infamous_weapon_nft;
        use infamous::infamous_accessory_nft;
        use std::string::{utf8};

        timestamp::set_time_has_started_for_testing(framework);


        let user_addr = signer::address_of(user);
        account::create_account_for_test(user_addr);
        
        infamous_manager_cap::initialize(user);
        infamous_nft::initialize(user);
        infamous_weapon_nft::initialize(user);
        infamous_accessory_nft::initialize(user);
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
        let face_accessory = utf8(b"null");
        let eyes = utf8(b"black eyes");
        let hair = utf8(b"bob cut 1 (navy blue)");
        let mouth = utf8(b"closed");
        let neck = utf8(b"null");
        let tattoo = utf8(b"null");
        let gender = utf8(b"female");
        let weapon = utf8(b"dagger");
        let tier = utf8(b"1");
        let grade = utf8(b"iron");
        let attributes = utf8(b"40");

         open_box(user,
          token_index_1_name,
         background, 
         clothing, attributes, 
         earrings, attributes, eyebrows, 
         face_accessory, attributes, 
         eyes, hair, 
         mouth, attributes,
         neck, attributes, 
         tattoo, attributes, 
         gender,
         weapon, tier, grade, attributes
         );


    }

    
       
}