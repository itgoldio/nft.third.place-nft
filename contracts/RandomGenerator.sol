pragma ton-solidity ^0.47.0;
pragma AbiHeader pubkey;
pragma AbiHeader expire;
pragma AbiHeader time;

contract RandomGenerator {

    // need to optimize the initialization and filling of the array with pieces
    uint16 constant STEP_SIZE = 100;

    uint16[] _particles;
    uint16 _numOfParticles;
    
    uint128 _minBalance;
    uint256 _systemKey;

    bool _active;

    event RandomParticleWasGenerated(address recipient, uint256 particleId);

    /// @param systemKey contract management public key
    /// @param minBalance it is needed to prevent the balance from being reset and the contract is frozen
    /// @param numOfParticles array size
    constructor(
        uint256 systemKey,
        uint128 minBalance,
        uint16 numOfParticles
    ) public {
        tvm.accept();

        _minBalance = minBalance;
        _systemKey = systemKey;
        _numOfParticles = numOfParticles;
        _active = false;
    }

    /// This method is necessary to fill the array. Due to the gas limit in the transaction, 
    /// it is impossible to immediately fill a large array with numbers. This method needs 
    /// to be called several times ( depending on the size of the array )
    function fillParticlesArray() public onlyOwner checkBalance  {
        require(!_active, 104);
        tvm.accept();

        uint16 limit;
        if (uint16(_particles.length) + STEP_SIZE < _numOfParticles) {
            limit = uint16(_particles.length) + STEP_SIZE;
        } else {
            limit = _numOfParticles;
            _active = true;
        }

        for (uint16 i = uint16(_particles.length); i < limit; i++) {
            _particles.push(i);
        }
    }

    /// This method can be called only after the array is 
    /// fully initialized ( _active must be true).
    function getRandomParticle(address recipient) public onlyOwner checkBalance isActive returns(uint256 particleId) {
        require(_particles.length > 0, 103);
        tvm.accept();

        uint16 random = uint16(_genNumber(_particles.length));
        particleId = _particles[random];
        
        delete _particles[random];
        _particles[random] = _particles[_particles.length - 1];
        _particles.pop();

        emit RandomParticleWasGenerated(recipient, particleId);
    }

    function _genNumber(uint limit) private pure returns(uint64 number) {
        tvm.accept();

        rnd.shuffle();
        number = uint64(rnd.next(limit));
    }

    function getFreeParticles() public view returns (uint16[] particles) {
        return _particles;
    }

    function getMinBalance() public view returns (uint128 minBalance) {
        return _minBalance;
    }

    function destruct(address dest) public onlyOwner {
        selfdestruct(dest);
    }

    modifier onlyOwner {
        require(msg.pubkey() == _systemKey, 101);
        _;
    }

    modifier checkBalance {
        require(address(this).balance > _minBalance, 102);
        _;
    }

    modifier isActive{
        require(_active, 104);
        _;
    }

}