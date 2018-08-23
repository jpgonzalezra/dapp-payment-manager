pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./DateTime.sol";

contract PaymentManager is Ownable {

    using SafeMath for uint256;

    struct Employee {
        uint256 index;
        uint256 amount;
        uint8 nextPayDate;
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

        uint8 currentMonth;
        (, currentMonth) = getCurrentTime();
        require(currentMonth == employee.nextPayDate);

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
    function addEmployee(address _address, uint256 _amount) public onlyOwner {

        require(_address != address(0));
        require(_amount > 0);

        uint8 nextPayDate = getNextPayDate();
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

        employeesIndex.length = employeesIndex.length.sub(1);

        emit DeleteEmployee(_address);

    }

    /**
    * @dev update a salary to the contract.
    * @param _address The address of the employee to update.
    * @param _newAmount The new number of salary owned by the employee.
    */
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
    function getNextPayDate() private view returns (uint8 time) {

        uint16 currentYear;
        uint8 currentMonth;
        (currentYear, currentMonth) = getCurrentTime();


        uint8 nextMonth;
        (, nextMonth) = DateTime.getNextMonth(currentYear, currentMonth);

        return nextMonth;
    }

    /**
    * @dev Returns the current year and month.
    * @return year uint16 The current year.
    * @return month uint8 The current month.
    */
    function getCurrentTime() private view returns (uint16 year, uint8 month) {
        return getTime(now);
    }

    /**
    * @dev Returns the current year and month.
    * @param _time uint256 The timestamp of the time to query.
    * @return year uint16 The current year.
    * @return month uint8 The current month.
    */
    function getTime(uint256 _time) private pure returns (uint16 year, uint8 month) {
        year = DateTime.getYear(_time);
        month = DateTime.getMonth(_time);
    }

}