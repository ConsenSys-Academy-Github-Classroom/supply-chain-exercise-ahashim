// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract SupplyChain {

  /*
   * State variables
   */

  address public owner;
  uint public skuCount;

  mapping (uint => Item) public items;

  enum State {
    ForSale,
    Sold,
    Shipped,
    Received
  }

  struct Item {
    string name;
    uint sku;
    uint price;
    State state;
    address payable seller;
    address payable buyer;
  }


  /*
   * Events
   */

  event LogForSale(uint sku);
  event LogSold(uint sku);
  event LogShipped(uint sku);
  event LogReceived(uint sku);


  /*
   * Modifiers
   */

  modifier isOwner {
    require(msg.sender == owner, "Only the contract owner can call this function.");
    _;
  }

  modifier verifyCaller (address _address) {
    require (msg.sender == _address);
    _;
  }

  modifier paidEnough(uint _price) {
    require(msg.value >= _price);
    _;
  }

  modifier checkValue(uint _sku) {
    _; // refund them after payment for item
    uint price = items[_sku].price;
    uint amountToRefund = msg.value - price;
    items[_sku].buyer.transfer(amountToRefund);
  }

  // For each of the following modifiers, use what you learned about modifiers
  // to give them functionality. For example, the forSale modifier should
  // require that the item with the given sku has the state ForSale. Note that
  // the uninitialized Item.State is 0, which is also the index of the ForSale
  // value, so checking that Item.State == ForSale is not sufficient to check
  // that an Item is for sale. Hint: What item properties will be non-zero when
  // an Item has been added?

  modifier forSale(uint _sku) {
    require(items[_sku].state == State.ForSale && items[_sku].price > 0);
    _;
  }
  modifier sold(uint _sku) {
    require(items[_sku].state == State.Sold);
    _;
  }
  modifier shipped(uint _sku) {
    require(items[_sku].state == State.Shipped);
    _;
  }
  modifier received(uint _sku) {
    require(items[_sku].state == State.Received);
    _;
  }

  constructor() {
    owner = msg.sender;
    skuCount = 0;
  }

  function addItem(string memory _name, uint _price) public returns (bool) {
    emit LogForSale(skuCount);

    // add item to items mapping
    items[skuCount] = Item({
      name: _name,
      sku: skuCount,
      price: _price,
      state: State.ForSale,
      seller: payable(msg.sender),
      buyer: payable(address(0))
    });

    // increment skuCount & log event
    skuCount += 1;
    emit LogForSale(skuCount);

    return true;
  }

  function buyItem(uint sku) public payable forSale(sku) paidEnough(items[sku].price) checkValue(sku) {
    // transfer amount to seller
    items[sku].seller.transfer(items[sku].price);

    // set the buyer address
    items[sku].buyer = payable(msg.sender);

    // update item state
    items[sku].state = State.Sold;

    emit LogSold(sku);
  }

  function shipItem(uint sku) public sold(sku) verifyCaller(items[sku].seller) {
    items[sku].state = State.Shipped;

    emit LogShipped(sku);
  }

  // 2. Change the state of the item to received.
  // 3. Call the event associated with this function!
  function receiveItem(uint sku) public shipped(sku) verifyCaller(items[sku].buyer) {
    items[sku].state = State.Received;

    emit LogReceived(sku);
  }

  // Uncomment the following code block. it is needed to run tests
  function fetchItem(uint _sku) public view
    returns (string memory name, uint sku, uint price, uint state, address seller, address buyer)
  {
    name = items[_sku].name;
    sku = items[_sku].sku;
    price = items[_sku].price;
    state = uint(items[_sku].state);
    seller = items[_sku].seller;
    buyer = items[_sku].buyer;
    return (name, sku, price, state, seller, buyer);
  }
}
