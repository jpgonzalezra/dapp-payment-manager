pragma solidity ^0.4.24;

import 'openzeppelin-solidity/contracts/math/SafeMath.sol';
import 'openzeppelin-solidity/contracts/ownership/Ownable.sol';

contract PaymentManager is Ownable {

    using SafeMath for uint256;

    struct Employee {
        uint256 index;
        uint256 amount;
        uint256 nextPayDate;
    }

    address[] public employeesIndex;
    mapping (address => bool) public payees;
    mapping (address => Employee) private employees;

    event NewEmployee(address employee, uint256 amount);
    event UpdateSalary(address employee, uint256 newAmount);
    event DeleteEmployee(address employee);


    /**
    * @dev payable fallback
    */
    function () external payable {}

    // ["0x583031d1113ad414f02576bd6afabfb302140225","0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db","0x14723a09acff6d2a60dcdf7aa4aff308fddc160c"], ["3000000000000000000","4000000000000000000","2000000000000000000"]

    /**
    * @dev Constructor
    */
    constructor(address[] _employees, uint256[] _amounts) public payable {

        require(_employees.length == _amounts.length);
        require(_employees.length > 0);

        for (uint256 i = 0; i < _employees.length; i++) {
            addEmployee(_employees[i], _amounts[i]);
        }

    }

    /**
    * @dev Claim your pay of the balance.
    */
    function claim() public {

        require(payees[msg.sender]);

        Employee storage employee = employees[msg.sender];
        require(now > employee.nextPayDate);

        uint256 payment = employee.amount;
        require(payment > 0);

        assert(address(this).balance >= payment);
        msg.sender.transfer(payment);
        employee.nextPayDate = getNextPayDate();

    }

    /**
    * @dev Add a new employee to the contract.
    * @param _address The address of the employee to add.
    * @param _amount The number of salary owned by the employee.
    */
    //"0xdd870fa1b7c4700f2bd7f44238821c26f7392148","1000000000000000000"
    function addEmployee(address _address, uint256 _amount) public onlyOwner {

        require(_address != address(0));
        require(_amount > 0);

        uint256 nextPayDate = getNextPayDate();
        employeesIndex.push(_address);
        uint256 index = employeesIndex.length.sub(1);
        employees[_address] = Employee(index, _amount, nextPayDate);
        payees[_address] = true;

        emit NewEmployee(_address, _amount);

    }

    /**
    * @dev Remove a new employee to the contract.
    * @param _address The address of the employee to add.
    */
    function deleteEmployee(address _address) public onlyOwner {

        require(_address != address(0));
        require(employeesIndex.length > 0);

        payees[_address] = false;

        uint rowToDelete = employees[_address].index;

        uint index = employeesIndex.length.sub(1);
        address keyToMove = employeesIndex[index];

        employeesIndex[rowToDelete] = keyToMove;
        employees[keyToMove].index = rowToDelete;

        emit DeleteEmployee(_address);

    }

    /**
    * @dev update a salary to the contract.
    * @param _address The address of the employee to update.
    * @param _newAmount The new number of salary owned by the employee.
    */
    //"0xdd870fa1b7c4700f2bd7f44238821c26f7392148","2000000000000000000"
    function updateSalary(address _address, uint256 _newAmount) public onlyOwner {

        require(_address != address(0));
        require(_newAmount > 0);
        require(payees[_address]);

        Employee storage employee = employees[_address];
        require(employee.amount != 0);

        employee.amount = _newAmount;

        emit UpdateSalary(_address, _newAmount);

    }

    /**
    * @dev retrieve employee.
    * @param _address The address of the employee to add.
    */
    function retrieveEmployee(address _address) public view onlyOwner returns (uint256 index, uint256 amount, uint256 nextPayDate) {

        require(_address != address(0));
        require(payees[_address]);

        Employee memory employee = employees[_address];

        return (employee.index, employee.amount, employee.nextPayDate);

    }

    /**
    * @dev Calculate the next payment.
    */
    function getNextPayDate() private view returns (uint256 time) {
        uint256 nextPayDate = now.add(30 days);
        return nextPayDate;
    }

}