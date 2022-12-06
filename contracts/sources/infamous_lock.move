/// This module provides the lock of Infamous Token.
/// InfamousLock used to lock infamous nft and store lock time, and store used time
module infamous::infamous_lock {

    use std::error;
    use std::signer;
    use std::vector;
    use std::option::{Self, Option};
    use std::string::{String};
    use aptos_std::table::{Self, Table};
    use aptos_framework::timestamp;
    use aptos_token::token::{Self, TokenId};
    use infamous::infamous_common;
    use infamous::infamous_manager_cap;
    use infamous::infamous_backend_auth;
    use infamous::infamous_backend_open_box;
    use infamous::infamous_nft;

    friend infamous::infamous_upgrade_level;

    //
    // Errors
    //
    /// Error when infamous token not opened.
    const ETOKEN_NOT_OPENED:u64 = 1;
    /// Error when lock token not owned by sender.
    const ETOKEN_NOT_OWNED_BY_SENDER: u64 = 2;
    /// Error when LockInfo store not initalized.
    const ELOCK_INFO_NOT_PUBLISHED: u64 = 3;
    /// Error when called un_lock when token is not Locked.
    const ETOKEN_NOT_LOCKED: u64 = 4;
    /// Error when call lock when token is already loaked.
    const ETOKEN_ALREADY_LOCKED: u64 = 5;
    /// Error when take time to use not enough.
    const ELOCK_TIME_NOT_ENOUGH: u64 = 6;
    /// Error when unlock_by_admin was called by not authed account.
    const EACCOUNT_MUSTBE_AUTHED: u64 = 7;
    /// Error when unlock token not owned by sender
    const ETOKEN_NOT_LOCKED_BY_THIS_ACCOUNT: u64 = 8;
    
    


    
    struct LockingTime has store, drop {
        // lock start time
        start: u64,
        // take used time
        lock_time_used: u64,
    }

    // store in lokcer account
    struct TokenLocks has key {
        // user locking tokenIds
        locking: vector<TokenId>,
    }


    // store in manager account
    struct TokenLocksData has key {
        // all locking tokenIds
        locking_tokens: vector<TokenId>,
        // locking tokenId address map
        locking_token_address: Table<TokenId, address>,
        // locking tokenIs LockingTime map
        locking_time: Table<TokenId, LockingTime>,
    }

    /// lock infamous nft, record time, transfer to manager addr and record token lockes
    public entry fun lock_infamous_nft(sender: &signer, name: String,) acquires TokenLocks, TokenLocksData {
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);

        
        // resolve token id
        let creator = manager_addr;
        let collection = infamous_common::infamous_collection_name();
        let token_id = infamous_nft::resolve_token_id(creator, collection, name);

        assert!(infamous_backend_open_box::is_box__opened(token_id), error::invalid_argument(ETOKEN_NOT_OPENED));

        token::opt_in_direct_transfer(sender, true);
        let sender_addr = signer::address_of(sender);
        assert!(token::balance_of(sender_addr, token_id) == 1, error::invalid_argument(ETOKEN_NOT_OWNED_BY_SENDER));
        token::direct_transfer(sender, &manager_signer, token_id, 1);
        add_token_locks(sender, sender_addr, token_id);
        add_token_locks_data(&manager_signer, manager_addr, sender_addr, token_id);
        
    }

    // unlock 
    public entry fun unlock_infamous_nft(sender: &signer, name: String,) acquires TokenLocks, TokenLocksData {
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);

        
        // resolve token id
        let creator = manager_addr;
        let collection = infamous_common::infamous_collection_name();
        let token_id = infamous_nft::resolve_token_id(creator, collection, name);

        let locking_token_address = &borrow_global<TokenLocksData>(manager_addr).locking_token_address;
        let locker_addr = *table::borrow(locking_token_address, token_id);
        let sender_addr = signer::address_of(sender);
        assert!(locker_addr == sender_addr, error::unauthenticated(ETOKEN_NOT_LOCKED_BY_THIS_ACCOUNT));

        remove_token_locks(locker_addr, token_id);
        remove_token_locks_data(manager_addr, token_id);
        token::direct_transfer(&manager_signer, sender, token_id, 1);
    }

    // unlock by admin, called by authed account to auto unlock nfts
    public entry fun unlock_infamous_nft_admin(sender: &signer, name: String,) acquires TokenLocks, TokenLocksData {
        
        let sender_addr = signer::address_of(sender);
        assert!(infamous_backend_auth::has_capability(sender_addr), error::unauthenticated(EACCOUNT_MUSTBE_AUTHED));

        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);

        
        let creator = manager_addr;
        let collection = infamous_common::infamous_collection_name();
        let token_id = infamous_nft::resolve_token_id(creator, collection, name);

        let locking_token_address = &borrow_global<TokenLocksData>(manager_addr).locking_token_address;
        let locker_addr = *table::borrow(locking_token_address, token_id);

        remove_token_locks(locker_addr, token_id);
        remove_token_locks_data(manager_addr, token_id);
        
        token::transfer(&manager_signer, token_id, locker_addr, 1);
    }

    /// get token locked address
    public fun token_lock_address(token_id: TokenId): Option<address> acquires TokenLocksData {
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        assert!(exists<TokenLocksData>(manager_addr), error::invalid_argument(ELOCK_INFO_NOT_PUBLISHED));
        let locking_token_address = &borrow_global<TokenLocksData>(manager_addr).locking_token_address;
        let locker_addr = option::none();
        if(table::contains(locking_token_address, token_id)) {
            locker_addr = option::some(*table::borrow(locking_token_address, token_id));
        };
        locker_addr
    }

    /// get token locked time
    public fun get_available_time(token_id: TokenId): u64 acquires TokenLocksData {
        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        assert!(exists<TokenLocksData>(manager_addr), error::invalid_argument(ELOCK_INFO_NOT_PUBLISHED));
        let locking_time = &borrow_global<TokenLocksData>(manager_addr).locking_time;
        assert!(table::contains(locking_time, token_id), error::invalid_argument(ETOKEN_NOT_LOCKED));
        let lock_time = table::borrow(locking_time, token_id);
        let avaliable = timestamp::now_seconds() - lock_time.start - lock_time.lock_time_used;
        avaliable
    }

    /// use lock time
    public(friend) fun take_times_to_use(token_id: TokenId, seconds: u64) acquires TokenLocksData {
        let available_time = get_available_time(token_id);
        assert!(available_time >= seconds, error::invalid_argument(ELOCK_TIME_NOT_ENOUGH));

        let manager_signer = infamous_manager_cap::get_manager_signer();
        let manager_addr = signer::address_of(&manager_signer);
        assert!(exists<TokenLocksData>(manager_addr), error::invalid_argument(ELOCK_INFO_NOT_PUBLISHED));
        let locking_time = &mut borrow_global_mut<TokenLocksData>(manager_addr).locking_time;
        assert!(table::contains(locking_time, token_id), error::invalid_argument(ETOKEN_NOT_LOCKED));
        let lock_time = table::borrow_mut(locking_time, token_id);
        lock_time.lock_time_used = lock_time.lock_time_used + seconds;
    }

    /// remove locked token
    fun remove_token_locks(sender_addr: address, token_id: TokenId) acquires TokenLocks {
        assert!(exists<TokenLocks>(sender_addr), error::not_found(ETOKEN_NOT_LOCKED));

        let locks = borrow_global_mut<TokenLocks>(sender_addr);
        let locking = &mut locks.locking;
        infamous_common::remove_element(locking, &token_id);

    }

    
    fun remove_token_locks_data(manager_addr: address, token_id: TokenId) acquires TokenLocksData {
        assert!(exists<TokenLocksData>(manager_addr), error::not_found(ETOKEN_NOT_LOCKED));

        let locks_data = borrow_global_mut<TokenLocksData>(manager_addr);
        let locking_tokens = &mut locks_data.locking_tokens;
        infamous_common::remove_element(locking_tokens, &token_id);

        let locking_token_address = &mut locks_data.locking_token_address;
        assert!(table::contains(locking_token_address, token_id), error::not_found(ETOKEN_NOT_LOCKED));
        let _address = table::remove(locking_token_address, token_id);

        let locking_time = &mut locks_data.locking_time;
        assert!(table::contains(locking_time, token_id), error::not_found(ETOKEN_NOT_LOCKED));
        let _lock_time = table::remove(locking_time, token_id);
    }

    fun add_token_locks(sender: &signer, sender_addr: address, token_id: TokenId) acquires TokenLocks {
        initialize_token_locks(sender);
        let locks = borrow_global_mut<TokenLocks>(sender_addr);
        let locking = &mut locks.locking;
        assert!(!vector::contains(locking, &token_id), error::already_exists(ETOKEN_ALREADY_LOCKED));
        infamous_common::add_element(locking, token_id);
    }

    fun add_token_locks_data(manager: &signer, manager_addr: address, locker_addr:address, token_id: TokenId) acquires TokenLocksData {
        initialize_token_locks_data(manager);
        let locks_data = borrow_global_mut<TokenLocksData>(manager_addr);
        let locking_tokens = &mut locks_data.locking_tokens;
        assert!(!vector::contains(locking_tokens, &token_id), error::already_exists(ETOKEN_ALREADY_LOCKED));
        infamous_common::add_element(locking_tokens, token_id);

        let locking_token_address = &mut locks_data.locking_token_address;
        assert!(!table::contains(locking_token_address, token_id), error::already_exists(ETOKEN_ALREADY_LOCKED));
        table::add(locking_token_address, token_id, locker_addr);

        let locking_time = &mut locks_data.locking_time;
        assert!(!table::contains(locking_time, token_id), error::already_exists(ETOKEN_ALREADY_LOCKED));
        table::add(locking_time, token_id, LockingTime{
                 start: timestamp::now_seconds(),
                 lock_time_used: 0,
             });
    }



    fun initialize_token_locks(account: &signer) {
        let account_addr = signer::address_of(account);
        if(!exists<TokenLocks>(account_addr)) {
            move_to(
                account,
                TokenLocks {
                    locking: vector::empty<TokenId>(),
                }
            );
        }
    }

    fun initialize_token_locks_data(account: &signer) {
        let account_addr = signer::address_of(account);
        if(!exists<TokenLocksData>(account_addr)) {
            move_to(
                account,
                TokenLocksData {
                    locking_tokens: vector::empty<TokenId>(),
                    locking_token_address: table::new<TokenId, address>(),
                    locking_time: table::new<TokenId, LockingTime>(),
                }
            );
        }
    }


    

    #[test(framework = @0x1, user = @infamous, receiver = @0xBB)]
    public fun end_to_end(user: &signer, receiver: &signer, framework: &signer) acquires TokenLocks, TokenLocksData { 

        use aptos_framework::account; 
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
        let attributes = utf8(b"100");

         infamous_backend_open_box::open_box(user,
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

        lock_infamous_nft(receiver, token_index_1_name);

        let time = get_available_time(token_id);
        assert!(time == 0, 1);

        timestamp::fast_forward_seconds(1000);
        let time1 = get_available_time(token_id);
        assert!(time1 == 1000, 1);


        take_times_to_use(token_id, 33);
        let time2 = get_available_time(token_id);
        assert!(time2 == 967, 1);

        unlock_infamous_nft(receiver, token_index_1_name);

    


    }


}