//
//  DailyFoodReportViewModel.swift
//  Plum
//
//  Created by Denys Hryshyn on 28.06.2023.
//

import Foundation

final class DailyFoodReportViewModel {
    
    // MARK: - Properties
    private var foodData: [String: [DailyFoodReportModel]]
    private let selectedDate: Date
    private let isFromHome: Bool
    
    let networkingService = FirebaseService.shared
    
    var reloadData: (() -> Void)?
    var title = "Daily food report"
    
    var data: [String: [DailyFoodReportModel]] {
        foodData
    }
    
    //MARK: - Init
    init(foodData: [String: [DailyFoodReportModel]], date: Date, isFromHome: Bool) {
        self.foodData = foodData
        self.selectedDate = date
        self.isFromHome = isFromHome
        
        if !isFromHome {
            getRecord()
        }
    }
    
    //MARK: - Funcs
    func getRecord() {
        Task {
            var foodItems = [FoodAndDish]()
            let foods = await getFoodsAsync()
            let foodsArr = foods.map { FoodAndDish.food($0) }
            foodItems += foodsArr
            
            let dishes = await getDishesAsync()
            let dishesArr = dishes.map { FoodAndDish.dish($0) }
            foodItems += dishesArr
            
            let sortedFoodItems = foodItems.sorted { (item1, item2) -> Bool in
                switch (item1, item2) {
                case let (.food(data1), .food(data2)):
                    return data1.dateValue < data2.dateValue
                case let (.dish(data1), .dish(data2)):
                    return data1.dateValue < data2.dateValue
                case let (.dish(data1), .food(data2)):
                    return data1.dateValue < data2.dateValue
                case let (.food(data1), .dish(data2)):
                    return data1.dateValue < data2.dateValue
                }
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.foodData = self.getDailyFoodReportData(sortedFoodItems)
                self.reloadData?()
            }
        }
    }
    
    private func getFoodsAsync() async -> [Food] {
        await withCheckedContinuation { continuation in
            networkingService.getGoodsHistory(fromDate: selectedDate, toDate: selectedDate) { foods in
                continuation.resume(returning: foods)
            }
        }
    }
    
    private func getDishesAsync() async -> [MyDishesModel] {
        await withCheckedContinuation { continuation in
            networkingService.getDishes(fromDate: selectedDate, toDate: selectedDate) { dishes in
                continuation.resume(returning: dishes)
            }
        }
    }
    
    private func getDailyFoodReportData(_ foods: [FoodAndDish]) -> [String: [DailyFoodReportModel]] {
        var finalDict: [String: [DailyFoodReportModel]] = [:]
        
        for s in getAllDateStrings() {
            finalDict[s] = []
            
            for f in foods {
                switch f {
                case .food(let food):
                    if getMealTimeString(by: food.date) == s {
                        finalDict[getMealTimeString(by: food.date)]?.append(DailyFoodReportModel(food: f))
                    }
                case .dish(let dish):
                    if getMealTimeString(by: dish.date) == s {
                        finalDict[getMealTimeString(by: dish.date)]?.append(DailyFoodReportModel(food: f))
                    }
                }
            }
        }
        
        return finalDict
    }
    
    private func getMealTimeString(by date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Locale.is12HoursFormat() ? "hh:mm a" : "HH:mm"
        let timeString = dateFormatter.string(from: date.startOfHour() ?? Date())
        return Locale.is12HoursFormat() ? timeString : timeString
    }
    
    private func getAllDateStrings() -> [String] {
        let loc = Locale.is12HoursFormat()
        if loc {
            return [
                "12:00 AM",
                "01:00 AM",
                "02:00 AM",
                "03:00 AM",
                "04:00 AM",
                "05:00 AM",
                "06:00 AM",
                "07:00 AM",
                "08:00 AM",
                "09:00 AM",
                "10:00 AM",
                "11:00 AM",
                "12:00 PM",
                "01:00 PM",
                "02:00 PM",
                "03:00 PM",
                "04:00 PM",
                "05:00 PM",
                "06:00 PM",
                "07:00 PM",
                "08:00 PM",
                "09:00 PM",
                "10:00 PM",
                "11:00 PM"
            ]
        } else {
            return [
                "00:00",
                "01:00",
                "02:00",
                "03:00",
                "04:00",
                "05:00",
                "06:00",
                "07:00",
                "08:00",
                "09:00",
                "10:00",
                "11:00",
                "12:00",
                "13:00",
                "14:00",
                "15:00",
                "16:00",
                "17:00",
                "18:00",
                "19:00",
                "20:00",
                "21:00",
                "22:00",
                "23:00"
            ]
        }
    }
}
