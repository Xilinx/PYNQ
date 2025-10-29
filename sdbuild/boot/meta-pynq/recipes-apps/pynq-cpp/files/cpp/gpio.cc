#include "gpio.h"

#define DEBUG

GPIO::GPIO(uint32_t gpio_index, std::string direction)
{
    if (direction != "in" && direction != "out") {
        std::cerr << "Direction must be 'in' or 'out'" << std::endl;
        return;
    }

    // Set member variables
    this->gpio_index = gpio_index;
    this->direction = direction;
    this->gpio_base_path = "/sys/class/gpio/gpio" + std::to_string(gpio_index) + "/";

    // Export GPIO if not already exported
    if (!std::filesystem::exists(this->gpio_base_path)) {
        std::ofstream export_file("/sys/class/gpio/export");
        if (!export_file.is_open()) {
            std::cerr << "Failed to open export file" << std::endl;
            return;
        }
        export_file << gpio_index;
        export_file.close();
    }

    // Set the direction
    std::ofstream direction_file(this->gpio_base_path + "direction");
    if (!direction_file.is_open()) {
        std::cerr << "Failed to open direction file" << std::endl;
        return;
    }
    direction_file << this->direction;
    direction_file.close();
}

GPIO::~GPIO()
{
}

uint32_t GPIO::read()
{
    // Check if direction is configured for input
    if (this->direction != "in") {
        std::cerr << "Cannot read from GPIO configured as output" << std::endl;
        return 0;
    }

    // Open the value file for reading
    std::ifstream value_file(this->gpio_base_path + "value");
    if (!value_file.is_open()) {
        std::cerr << "Failed to open value file for reading" << std::endl;
        return 0;
    }

    // Read the value and convert to integer
    std::string value_str;
    value_file >> value_str;
    value_file.close();

    uint32_t value = std::stoi(value_str);

    return value;
}

void GPIO::write(uint32_t value)
{
    // Check if direction is configured for output
    if (this->direction != "out") {
        std::cerr << "Cannot write to GPIO configured as input" << std::endl;
        return;
    }

    // Check if value is valid
    if (value != 0 && value != 1) {
        std::cerr << "Value must be 0 or 1" << std::endl;
        return;
    }

    // Open the value file for writing
    std::ofstream value_file(this->gpio_base_path + "value");
    if (!value_file.is_open()) {
        std::cerr << "Failed to open value file for writing" << std::endl;
        return;
    }

    // Write the value as string
    value_file << value;
    value_file.close();
}

void GPIO::unexport()
{
    // Check if GPIO path exists before attempting to unexport
    if (std::filesystem::exists(this->gpio_base_path)) {
        std::ofstream unexport_file("/sys/class/gpio/unexport");
        if (!unexport_file.is_open()) {
            std::cerr << "Failed to open unexport file" << std::endl;
            return;
        }

        unexport_file << this->gpio_index;
        unexport_file.close();
    }
}

bool GPIO::is_exported()
{
    // Check if the GPIO base path exists
    return std::filesystem::exists(this->gpio_base_path);
}

std::string get_gpio_base_path(const std::string& target_label)
{
    std::vector<std::string> valid_labels;
    
    if (!target_label.empty()) {
        valid_labels.push_back(target_label);
    } else {
        valid_labels.push_back("zynqmp_gpio");
        valid_labels.push_back("zynq_gpio");
    }

    // Walk through /sys/class/gpio directory
    std::string gpio_base_dir = "/sys/class/gpio";
    
    try {
        for (const auto& entry : std::filesystem::directory_iterator(gpio_base_dir)) {
            if (entry.is_directory()) {
                std::string dir_name = entry.path().filename().string();
                
                // Check if directory name contains 'gpiochip'
                if (dir_name.find("gpiochip") != std::string::npos) {
                    std::string label_file_path = entry.path() / "label";
                    
                    // Read the label file
                    std::ifstream label_file(label_file_path);
                    if (label_file.is_open()) {
                        std::string label;
                        std::getline(label_file, label);
                        label_file.close();
                        
                        // Remove trailing whitespace (equivalent to rstrip())
                        label.erase(label.find_last_not_of(" \t\r\n") + 1);
                        
                        // Check if label is in valid_labels
                        for (const auto& valid_label : valid_labels) {
                            if (label == valid_label) {
                                return entry.path().string();
                            }
                        }
                    }
                }
            }
        }
    } catch (const std::filesystem::filesystem_error& e) {
        std::cerr << "Error accessing filesystem: " << e.what() << std::endl;
    }

    return ""; // Return empty string if not found
}

uint32_t get_gpio_npins(const std::string& target_label)
{
    std::string base_path = get_gpio_base_path(target_label);

    if (base_path.empty()) {
        #ifdef DEBUG
        std::cerr << "GPIO base path not found for label: " << target_label << std::endl;
        #endif
        return 0; 
    }

    std::ifstream ngpio_file(base_path + "/ngpio");
    if (!ngpio_file.is_open()) {
        return 0;
    }

    std::string ngpio_str;
    std::getline(ngpio_file, ngpio_str);
    ngpio_file.close();

    // Extract only digits
    std::string digits_only;
    for (char c : ngpio_str) {
        if (std::isdigit(c)) {
            digits_only += c;
        }
    }

    if (digits_only.empty()) {
        return 0;
    }

    try {
        return std::stoi(digits_only);
    } catch (...) {
        return 0;
    }
}