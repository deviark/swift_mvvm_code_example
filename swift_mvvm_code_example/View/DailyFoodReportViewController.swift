//
//  DailyFoodReportViewController.swift
//  Plum
//
//  Created by Denys Hryshyn on 27.06.2023.
//

import UIKit
import PassioNutritionAISDK

class DailyFoodReportViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet private weak var tableView: UITableView!
    
    // MARK: - BindableType
    var viewModel: DailyFoodReportViewModel!
    
    // MARK: - Vars
    private let floatingButon = FloatingButton()
    private var floatingButonCollapsedHeightContstraint: NSLayoutConstraint!
    
    private var selectedDateFromPlus: Date?
    
    var selectedModelID: String?
    
    var currentLinesAmount: CGFloat = 0
    
    let passioSDK = PassioNutritionAI.shared
    let connector = PassioInternalConnector.shared
    
    var passioConfig = PassioConfiguration(key: PassioExternalConnector.shared.passioKeyForSDK)
    
    //MARK: - View Lifecycle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        selectedDateFromPlus = nil
        if !viewModel.data.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                self.scrollToNeededItem()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        title = viewModel.title
        
        initFloatingButtonContstraints()
        setupFloatButton()
        
        setupUI()
        setupTableView()
        
        floatingButon.delegate = self
        PassioNutritionAI.shared.statusDelegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Funcs
    private func initFloatingButtonContstraints() {
        floatingButonCollapsedHeightContstraint = floatingButon.heightAnchor.constraint(equalToConstant: 118)
    }
    
    func configurePassioSDK() {
        PassioNutritionAI.shared.statusDelegate = self
        PassioNutritionAI.shared.configure(passioConfiguration: passioConfig) { status in
            print(" passioSDKState === \(status)")
        }
    }
    
    private func setupUI() {
        self.navigationItem.leftBarButtonItem = nil
        self.navigationItem.hidesBackButton = true
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension;
        tableView.estimatedRowHeight = 67 + 16 + 28
        let timelineTableViewCellNib = UINib(nibName: "TimelineTableViewCellNew", bundle: Bundle(for: TimelineTableViewCellNew.self))
        self.tableView.register(timelineTableViewCellNib, forCellReuseIdentifier: "TimelineTableViewCell")
    }
    
    private func setupFloatButton() {
        tabBarController?.tabBar.isHidden = true
        
        view.addSubview(floatingButon)
        floatingButon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            floatingButon.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 30),
            floatingButon.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            floatingButon.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            floatingButonCollapsedHeightContstraint
        ])
        
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
        blur.frame = self.view.bounds
        blur.setupBlur()
        floatingButon.addSubview(blur)
        floatingButon.sendSubviewToBack(blur)
        floatingButon.homeButton.setImage(R.image.homeIconSelected()?.withTintColor(R.color.button_blue()!), for: .normal)
        floatingButon.searchButton.setImage(R.image.searchIcon(), for: .normal)
        floatingButon.scanButton.setImage(R.image.scanIcon(), for: .normal)
    }
    
    private func scrollToNeededItem() {
        let numberOfSections = self.tableView.numberOfSections
        let numberOfRows = self.tableView.numberOfRows(inSection: numberOfSections-1)
        
        let indexPath = IndexPath(row: numberOfRows-17 , section: numberOfSections-1)
        self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
    }
    
    private func undoAction() {
        guard let id = selectedModelID else { return }

        viewModel.networkingService.deleteGoods(id)
    }
    
    private func scanSearchAlert() {
        let refreshAlert = UIAlertController(title: "", message: "Just scan or search or the food you're eating and let us handle the rest", preferredStyle: UIAlertController.Style.alert)

        refreshAlert.addAction(UIAlertAction(title: "Search", style: .default, handler: { (action: UIAlertAction!) in
            self.searchButtonPressed()
        }))

        refreshAlert.addAction(UIAlertAction(title: "Scan food", style: .default, handler: { (action: UIAlertAction!) in
            self.scanButtonPressed()
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
              print("Handle Cancel Logic here")
        }))

        present(refreshAlert, animated: true, completion: nil)
    }
    
    private func saveFoodRecordsFromSearch(passioIDAndName: [PassioIDAndName?],
                                           micronutrients: Micronutrients?,
                                           macronutrients: Macronutrients?,
                                           date: Date) {
        let foodRecords = passioIDAndName.compactMap { $0?.passioID }
            .compactMap{ passioSDK.lookupPassioIDAttributesFor(passioID: $0) }
            .compactMap { FoodRecord(passioIDAttributes: $0,
                                     replaceVisualPassioID: nil,
                                     replaceVisualName: nil,
                                     scannedWeight: nil)
            }
        foodRecords.forEach {
            
            var fRecord = $0
            
            if let d = selectedDateFromPlus {
                fRecord.setFoodDate(with: d)
            } else {
                fRecord.setFoodDate(with: date)
            }
            
            let food = Food(with: fRecord, source: "text")
            
            if let micro = micronutrients {
                food.micronutrients = micro
            }
            
            if let macro = macronutrients {
                food.macronutrients = macro
            }
            
            let id = UUID().uuidString
            selectedModelID = id
            viewModel.networkingService.saveGoodsHistory(food, ids: id) { result in
                print(result)
            }
        }
    }
    
    private func goToScanScreen() {
        let storyboard = UIStoryboard.init(name: "Tabbar", bundle: nil)
        guard let currenciesVC = storyboard.instantiateViewController(identifier: "FoodScanViewController") as? FoodScanViewController else { return }
        currenciesVC.selectedDate = selectedDateFromPlus
        currenciesVC.delegate = self
        PreferencesService.isOpenScanFromHome = false
        currenciesVC.modalPresentationStyle = .overFullScreen
        present(currenciesVC, animated: false)
    }
    
    private func goToDishDetail(dish: MyDishesModel) {
        let storyboard = UIStoryboard.init(name: "AddDishesViewController", bundle: nil)
        guard let addNewDishVC = storyboard.instantiateViewController(identifier: "AddDishesViewController") as? AddDishesViewController else { return }
        addNewDishVC.selectedDate = dish.date
        var vc = addNewDishVC
        let vm = AddDishesViewModel(selectedScreenType: .update, selectedDishType: .foodLog, selectedDish: dish)
        vc.bind(to: vm)
        self.navigationController?.isNavigationBarHidden = false
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    //MARK: - Navigation
    private func goToDetail(food: Food, date: Date) {
        guard let vc = R.storyboard.detailCellViewController.detailCellViewController() else { return }
        let detailCellVC = vc
        detailCellVC.screenType = .food
        detailCellVC.food = food

        let foodRecord = food
        
        let quantity = foodRecord.selectedQuantity
        let title = foodRecord.selectedUnit.capitalized
        let weight = String(foodRecord.macronutrients.weight)
        let textAmount = quantity == Double(Int(quantity)) ? String(Int(quantity)) :
        String(quantity.roundDigits(afterDecimal: 1))
        let weightText = title == "g" ? "" : "(" + weight + " " + "g".localized + ") "
        let detailCellWeightText = title == "g" ? "" : "" + weight + " " + "g".localized + ""
        
        var calStr = "0"
        let cal = foodRecord.macronutrients.calories
        if 0 < cal, cal < 1e6 {
            calStr = String(Int(cal))
        }
        
        let carbs = String(foodRecord.macronutrients.carbs)
        let protein = String(foodRecord.macronutrients.protein)
        let fat = String(foodRecord.macronutrients.fat)
        
        detailCellVC.selectedFoodDate = foodRecord.date
        
        // Macronutrients
        detailCellVC.carbs = carbs
        detailCellVC.fat = fat
        detailCellVC.protein = protein
        detailCellVC.size = Int(foodRecord.macronutrients.weight)
        
        // Micronutrients
        detailCellVC.potassium = String(foodRecord.micronutrients.potassium)
        detailCellVC.sugars = String(foodRecord.micronutrients.sugars)
        detailCellVC.sodium = String(foodRecord.micronutrients.sodium)
        detailCellVC.vitaminE = String(foodRecord.micronutrients.vitaminE)
        detailCellVC.phosphorus = String(foodRecord.micronutrients.phosphorus)
        detailCellVC.calcium = String(foodRecord.micronutrients.calcium)
        detailCellVC.magnesium = String(foodRecord.micronutrients.magnesium)
        detailCellVC.polyunsaturatedFat = String(foodRecord.micronutrients.polyunsaturatedFat)
        detailCellVC.monounsaturatedFat = String(foodRecord.micronutrients.monounsaturatedFat)
        detailCellVC.vitaminC = String(foodRecord.micronutrients.vitaminC)
        detailCellVC.iron = String(foodRecord.micronutrients.iron)
        detailCellVC.fibers = String(foodRecord.micronutrients.fibers)
        detailCellVC.vitaminB6 = String(foodRecord.micronutrients.vitaminB6)
        detailCellVC.transFat = String(foodRecord.micronutrients.transFat)
        detailCellVC.vitaminD = String(foodRecord.micronutrients.vitaminD)
        detailCellVC.vitaminA = String(foodRecord.micronutrients.vitaminA)
        detailCellVC.vitaminB12 = String(foodRecord.micronutrients.vitaminB12)
        detailCellVC.cholesterol = String(foodRecord.micronutrients.cholesterol)
        
        detailCellVC.name = foodRecord.name.capitalized
        detailCellVC.unitSize = detailCellWeightText
        detailCellVC.calories = calStr
        detailCellVC.passioIDForCell = foodRecord.passioID
        detailCellVC.entity = foodRecord.entity
        
        detailCellVC.selectedDate = date
        
        PreferencesService.isOpenScanFromHome = false
        self.navigationController?.pushViewController(detailCellVC, animated: true)
    }
}

// MARK: - Table view data source

extension DailyFoodReportViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.data.keys.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TimelineTableViewCell", for: indexPath) as! TimelineTableViewCellNew
        var allKeys = [String]()
        let dictionary = viewModel.data
        
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        let amPmArray = Array(dictionary.keys)
          .compactMap(formatter.date(from:))
          .sorted()
          .map(formatter.string(from:))
        
        let sortedKeys = Locale.is12HoursFormat()
        ?
        amPmArray
        :
        Array(dictionary.keys).sorted(by: <) // ["A", "D", "Z"]
        
        for k in sortedKeys {
            allKeys.append(k)
        }
        
        let keyName = allKeys[indexPath.row]
        
        let model = viewModel.data[keyName].map({ $0 }) ?? []
        
        cell.setData(model: model, key: keyName)
        
        cell.reloadTVHandler = { [weak self] in
            self?.tableView?.beginUpdates()
            self?.tableView?.endUpdates()
        }
        
        cell.plusBtnTappedHandler = { [weak self] date in
            self?.selectedDateFromPlus = date
            self?.scanSearchAlert()
        }
        
        cell.tagTappedHandler = { [weak self] (f, date) in
            if let food = f {
                switch food {
                case .food(let foodItem):
                    self?.goToDetail(food: foodItem, date: date)
                case .dish(let dish):
                    self?.goToDishDetail(dish: dish)
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableView.automaticDimension
    }
}

// MARK: - BindableType
extension DailyFoodReportViewController: BindableType {
    func bindViewModel() {
        viewModel.reloadData = { [weak self] in
            guard let self = self else { return }
            self.tableView.reloadData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                self.scrollToNeededItem()
            }
        }
    }
}

// MARK: - FloatingButtonDelegate
extension DailyFoodReportViewController: FloatingButtonDelegate {
    func collapseFloatingButton() {
        floatingButonCollapsedHeightContstraint.isActive = true
    }
    
    func homeButtonPressed() {
        let storyboard = UIStoryboard.init(name: "Tabbar", bundle: nil)
        guard let currenciesVC = storyboard.instantiateViewController(identifier: "Tabbar") as? TabbarController else { return }
        PreferencesService.isOpenScanFromHome = true
        UIApplication.shared.windows.first?.rootViewController = currenciesVC
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
    
    func scanButtonPressed() {
        DispatchQueue.main.async { [weak self] in
            self?.goToScanScreen()
        }
    }
    
    func searchButtonPressed() {
        let storyboard = UIStoryboard.init(name: "Tabbar", bundle: nil)
        guard let currenciesVC = storyboard.instantiateViewController(identifier: "TextResearchViewController") as? TextResearchViewController else { return }
        currenciesVC.delegate = self
        currenciesVC.selectedDate = selectedDateFromPlus
        PreferencesService.isOpenScanFromHome = false
        currenciesVC.modalPresentationStyle = .overFullScreen
        present(currenciesVC, animated: false) {
            currenciesVC.presentSearchFoodScreen()
        }
    }
}

// MARK: - Passio Delegates
extension DailyFoodReportViewController: PassioStatusDelegate {
    
    func passioStatusChanged(status: PassioStatus) {
        DispatchQueue.main.async {
            //            self.startFoodDetection()
        }
    }
    
    func passioProcessing(filesLeft: Int) {
        DispatchQueue.main.async {
            print("Files left to Process \(filesLeft)")
        }
    }
    
    func completedDownloadingAllFiles(filesLocalURLs: [FileLocalURL]) {
        DispatchQueue.main.async {
            print("Completed downloading all files")
        }
    }
    
    func completedDownloadingFile(fileLocalURL: FileLocalURL, filesLeft: Int) {
        DispatchQueue.main.async {
            print("Files left to download \(filesLeft)")
        }
    }
    
    func downloadingError(message: String) {
        print("downloadError   ---- =\(message)")
    }
    
}

// MARK: - FoodScanViewControllerDelegate
extension DailyFoodReportViewController: FoodScanViewControllerDelegate {
    func addedFoodsFromScan(_ sender: FoodScanViewController, foods: [Food]) {
        self.dismiss(animated: true) { [weak self] in
            self?.selectedDateFromPlus = nil
            self?.viewModel.getRecord()
        }
    }
}

// MARK: - SearchFoodViewDelegate
extension DailyFoodReportViewController: SearchFoodViewDelegate {
    func undoActionWith(model: PassioNutritionAISDK.PassioIDAndName) {
        undoAction()
    }
    
    func popVC() {
        self.dismiss(animated: true)
        if let date = selectedDateFromPlus {
            selectedDateFromPlus = nil
            viewModel.getRecord()
        }
    }
    
    func userSelectedFoodItemViaText(passioIDAndName: [PassioNutritionAISDK.PassioIDAndName]?) {
        
    }
    
    func userSelectedFoodItemViaText(passioIDAndName: [PassioIDAndName?],
                                          micronutrients: Micronutrients?,
                                          macronutrients: Macronutrients?,
                                          date: Date) {
        
        //searchButtonPressed()
        
        saveFoodRecordsFromSearch(passioIDAndName: passioIDAndName, micronutrients: micronutrients, macronutrients: macronutrients, date: date)
    }
}
