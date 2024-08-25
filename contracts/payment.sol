// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
 interface IERC20Token {
    function transfer(address, uint256) external returns (bool);

    function approve(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Payment {
    // Owner of the contract (admin)
    address internal owner;

    // ERC20 token interface
    IERC20Token internal token;
      constructor(address _tokenAddress) {
        owner =  0x874069Fa1Eb16D44d622F2e0Ca25eeA172369bC1;
        token = IERC20Token(_tokenAddress);
    }
    struct Employee {
        string companyworkingfor;
        string nameofemployee;
        string position;
        uint256 salary;
        address payable useraddress;
        uint256 lastPaid;
        bool paid;
    }

    // Mapping from employee address to their details
    mapping(address => Employee) internal employees;
    // Separate mapping to track if an employee exists
    mapping(address => bool) internal employeeExistsMapping;

    // Array to keep track of all employee addresses
    address[] internal allEmployees;
    // Modifier to restrict access to the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    // Corrected modifier to check if the employee exists
    modifier employeeExists(address _employee) {
        require(employeeExistsMapping[_employee], "Employee does not exist");
        _;
    }
    // Events
    event EmployeeAdded(address indexed employee, uint256 salary);
    event EmployeeRemoved(address indexed employee);
    event SalaryPaid(address indexed employee, uint256 amount);

    // Constructor sets the owner of the contract
    // Function to add an employee
    function addEmployee(
        address _employee,
        string memory _company,
        string memory _name,
        string memory _position,
        uint256 _salary
    ) external onlyOwner {
        require(!employeeExistsMapping[_employee], "Employee already exists");
        require(_salary > 0, "Salary must be greater than 0");

        employees[_employee] = Employee({
            companyworkingfor: _company,
            nameofemployee: _name,
            position: _position,
            salary: _salary,
            useraddress: payable(_employee),
            paid: false,
            lastPaid: block.timestamp
        });
        employeeExistsMapping[_employee] = true;
        allEmployees.push(_employee); // Add the employee's address to the array
        emit EmployeeAdded(_employee, _salary);
    }

    // Function for the owner to remove an employee
    function removeEmployee(address _employee)
        public
        onlyOwner
        employeeExists(_employee)
    {
        delete employees[_employee]; // Reset the employee's data in the employees mapping
        employeeExistsMapping[_employee] = false; // Update the existence mapping to reflect removal
        // Find the index of the employee address in the allEmployees array
        uint256 index;
        bool found = false;
        for (uint256 i = 0; i < allEmployees.length; i++) {
            if (allEmployees[i] == _employee) {
                index = i;
                found = true;
                break;
            }
        }
        require(found, "Employee not found in the array");
        // Replace the removed employee's address with the last element in the array
        allEmployees[index] = allEmployees[allEmployees.length - 1];

        // Decrease the length of the array by one
        allEmployees.pop();
    }

    function getAllEmployeeAddresses() public view returns (address[] memory) {
        return allEmployees;
    }

    // Function to get details of an employee given their address
    function getEmployeeDetails(address _employee)
        public
        view
        employeeExists(_employee)
        returns (Employee memory)
    {
        return employees[_employee];
    }

    // Function to pay all employees at once
    function payAllEmployees() public onlyOwner {
        uint256 totalSalary = 0;
        for (uint256 i = 0; i < allEmployees.length; i++) {
            Employee storage employee = employees[allEmployees[i]];
            totalSalary += employee.salary;
        }

        require(token.balanceOf(address(this)) >= totalSalary, "Contract does not have enough tokens");

        for (uint256 i = 0; i < allEmployees.length; i++) {
            address payable employeeAddress = payable(allEmployees[i]);
            uint256 salary = employees[employeeAddress].salary;

            // Transfer ERC20 tokens from contract to employee
            bool success = token.transferFrom(address(this), employeeAddress, salary);
            require(success, "Transfer failed");

            // Update lastPaid and paid status
            employees[employeeAddress].lastPaid = block.timestamp;
            employees[employeeAddress].paid = true;
        }
    }

}
