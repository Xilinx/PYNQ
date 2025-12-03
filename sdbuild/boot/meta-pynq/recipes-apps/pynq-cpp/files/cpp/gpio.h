#ifndef GPIO_H
#define GPIO_H

#include <fstream>
#include <filesystem>
#include <unistd.h>
#include <iostream>
#include <string>
#include <vector>
#include <stdexcept>
#include <filesystem>

class GPIO
{
    /**
     * @class GPIO
     * @brief GPIO class to control GPIO pins
     * Each instance of this class represents a single GPIO pin.
     */
private:
    int gpio_index;
    std::string direction;
    std::string gpio_base_path;

public:
    /**
     * @brief Constructor for GPIO class
     * Initializes the GPIO pin with the given index and direction.
     * @param gpio_index Index of the GPIO pin
     * @param direction Direction of the GPIO pin ("in" or "out")
     */
    GPIO(uint32_t gpio_index, std::string direction);

    /**
     * @brief Destructor for GPIO class
     */
    ~GPIO();

    /**
     * @brief Read the value from the GPIO pin
     * @return Value read from the GPIO pin
     */
    uint32_t read();

    /**
     * @brief Write a value to the GPIO pin
     * @param value Value to write to the GPIO pin
     */
    void write(uint32_t value);

    /**
     * @brief Unexport the GPIO pin
     * Cleans up resources associated with the GPIO pin.
     */
    void unexport();

    /**
     * @brief Checks if the GPIO pin is exported
     * @return true if the GPIO pin is exported, false otherwise
     */
    bool is_exported();

    // Getters for member variables
    int get_index() const { return gpio_index; }
    std::string get_direction() const { return direction; }
    std::string get_gpio_path() const { return gpio_base_path; }


};


/**
 * @brief Gets the GPIO base path
 * @return Base path of the GPIO pin
 */
std::string get_gpio_base_path(const std::string& target_label = "");

/**
 * @brief Gets the number of GPIO pins available
 * @return Number of GPIO pins available
 */
uint32_t get_gpio_npins(const std::string& target_label = "");

#endif // GPIO_H