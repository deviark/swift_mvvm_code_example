//
//  TimelineTableViewCellNew.swift
//  Plum
//
//  Created by Denys Hryshyn on 27.06.2023.
//

import UIKit
import TTGTags

class TimelineTableViewCellNew: UITableViewCell {
    
    // MARK: - Defaults
    private enum Defaults {
        static let def2RawsSize: CGFloat = 80
        static let defEmptySize: CGFloat = 36
        static let defBottomPaddingPlusBtn: CGFloat = 12
        static let defExpBottomPaddingPlusBtn: CGFloat = 12
        static let defEmptyPaddingWidth: CGFloat = 0
        static let def2RawsPaddingWidth: CGFloat = 36
    }
    
    @IBOutlet private weak var tlView: UIView!
    @IBOutlet private weak var timeView: UIView!
    @IBOutlet private weak var timeText: UILabel!
    @IBOutlet private weak var descriptionLabelNew: UILabel!
    @IBOutlet private weak var pointView: UIView!
    @IBOutlet private weak var separatorView: UIView!
    
    @IBOutlet private weak var textCVView: UIView!
    @IBOutlet private weak var bgTextCVView: UIView!
    
    @IBOutlet private weak var expandBtn: UIButton!
    @IBOutlet private weak var plusBtn: UIButton!
    
    // Constraints
    @IBOutlet weak var textCVViewHeight: NSLayoutConstraint!
    @IBOutlet weak var plusBtnBottomPadding: NSLayoutConstraint!
    
    var isExpanded = false
    
    private var currentTime = ""
    private var tagsDict: [UInt: FoodAndDish] = [:]
    
    // Handlers
    var reloadTVHandler: (() -> ())?
    var plusBtnTappedHandler: ((Date) -> ())?
    var tagTappedHandler: ((FoodAndDish?, Date) -> ())?
    
    var textCV = TTGTextTagCollectionView()
    
    private var currentLinesAmount: CGFloat = 2 {
        didSet {
            self.expandBtn.isHidden = currentLinesAmount <= 2
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        textCVView.isHidden = true
        
        expandBtn.setImage(UIImage(systemName: "chevron.down", withConfiguration: UIImage.SymbolConfiguration(scale: .small))?.withRenderingMode(.alwaysTemplate), for: .normal)
        
        setTextCV()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        contentView.layer.sublayers?.filter{ $0 is CAShapeLayer }.forEach{ $0.removeFromSuperlayer() }
        drawDottedLine(start: CGPoint(x: 0, y: tlView.bounds.minY), end: CGPoint(x: 0, y: tlView.bounds.maxY), view: contentView)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        textCV.removeAllTags()
        contentView.subviews.filter { $0 is TTGTextTagCollectionView }.forEach { $0.removeFromSuperview() }
        self.contentView.addSubview(textCV)
    }
    
    private func setTextCV() {
        textCV = TTGTextTagCollectionView.init(frame: CGRect(x: textCVView.frame.minX,
                                                             y: textCVView.frame.minY,
                                                             width: textCVView.frame.width,
                                                             height: textCVView.frame.height))
        textCV.delegate = self
        textCV.manualCalculateHeight = false
        textCV.horizontalSpacing = 8
        textCV.verticalSpacing = 8
        textCV.contentInset = .init(top: 12, left: 12, bottom: 4, right: 4)
        textCV.alignment = .left
        textCV.numberOfLines = 2
        //textCV.intrinsicContentSize = textCVView.frame.size
        self.contentView.addSubview(textCV)
    }
    
    private func calculateHour(from str: String) -> Int {
        if let h = str.components(separatedBy: ":").first {
            return Int(h) ?? 0
        }
        
        return 0
    }
    
    private func updateUIBy(isFromMealSettings: Bool, isEmpty: Bool) {
        timeText.textColor = isFromMealSettings ? .white : .black
        textCV.isHidden = isEmpty ? true : false
        bgTextCVView.isHidden = isEmpty ? true : false
        plusBtn.isHidden = false
    
        if isFromMealSettings {
            separatorView.backgroundColor = isEmpty ? UIColor(red: 1, green: 0.35, blue: 0.37, alpha: 1) : UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
            pointView.backgroundColor = isEmpty ? UIColor(red: 1, green: 0.35, blue: 0.37, alpha: 1) : UIColor(red: 0.35, green: 0.73, blue: 1, alpha: 1)
            descriptionLabelNew.text = isEmpty ? "You forgot to eat" : ""
            timeView.backgroundColor = isEmpty ? UIColor(red: 1, green: 0.35, blue: 0.37, alpha: 1) : UIColor(red: 0.35, green: 0.73, blue: 1, alpha: 1)
        } else {
            separatorView.backgroundColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
            descriptionLabelNew.text = ""
            timeView.backgroundColor = .clear
            pointView.backgroundColor = .clear
        }
    }
    
    private func reloadConstraintValues(isEmpty: Bool) {
        expandBtn.isHidden = currentLinesAmount <= 2
        
        if isEmpty {
            plusBtnBottomPadding.constant = Defaults.defBottomPaddingPlusBtn
            textCVViewHeight.constant = Defaults.defEmptySize
        } else {
            plusBtnBottomPadding.constant = Defaults.defExpBottomPaddingPlusBtn
            textCVViewHeight.constant = isExpanded
            ?
            currentLinesAmount * 24 + ((currentLinesAmount - 1) * 8) + 24
            :
            Defaults.def2RawsSize
        }
    }
    
    private func getMealTimeString(by date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = Locale.is12HoursFormat() ? "hh:mm a" : "HH:mm"
        let timeString = dateFormatter.string(from: date.startOfHour() ?? Date())
        return Locale.is12HoursFormat() ? timeString : timeString
    }
    
    func setTextCollectionView(with data: [FoodAndDish]) {
                
        var totalData: [TTGTextTag] = []
        
        for datum in data {
            switch datum {
            case .food(let food):
                let content = TTGTextTagStringContent(text: food.name,
                                                      textFont: UIFont(name: "Inter-Semibold", size: 14),
                                                      textColor: UIColor(red: 0.32, green: 0.31, blue: 0.35, alpha: 1))
                let style = TTGTextTagStyle()
                style.borderColor = UIColor(red: 0.35, green: 0.73, blue: 1, alpha: 1)
                style.borderWidth = 1
                style.backgroundColor = UIColor(red: 0.35, green: 0.73, blue: 1, alpha: 0.1)
                style.cornerRadius = 6
                style.extraSpace = CGSize(width: 24, height: 4)
                style.shadowColor = .clear
                style.shadowRadius = 0
                style.shadowOpacity = 0
                style.maxWidth = (textCV.frame.width - 24) / 2
                
                let tag = TTGTextTag(content: content, style: style)
                
                tagsDict[tag.tagId] = datum
                
                totalData.append(tag)
            case .dish(let myDishesModel):
                let content = TTGTextTagStringContent(text: myDishesModel.name,
                                                      textFont: UIFont(name: "Inter-Semibold", size: 14),
                                                      textColor: UIColor(red: 0.32, green: 0.31, blue: 0.35, alpha: 1))
                let style = TTGTextTagStyle()
                style.borderColor = UIColor(red: 0.35, green: 0.73, blue: 1, alpha: 1)
                style.borderWidth = 1
                style.backgroundColor = UIColor(red: 0.35, green: 0.73, blue: 1, alpha: 0.1)
                style.cornerRadius = 6
                style.extraSpace = CGSize(width: 24, height: 4)
                style.shadowColor = .clear
                style.shadowRadius = 0
                style.shadowOpacity = 0
                style.maxWidth = (textCV.frame.width - 24) / 2
                
                let tag = TTGTextTag(content: content, style: style)
                
                tagsDict[tag.tagId] = datum
                
                totalData.append(tag)
            }
        }
        print("bef set intrinsicContentSize", textCV.intrinsicContentSize.height, textCV.intrinsicContentSize.width)
        // Add tag
        textCV.add(totalData)
        
        print("after set intrinsicContentSize", textCV.intrinsicContentSize.height, textCV.intrinsicContentSize.width)
        
        // !!! Never forget this !!!
        textCV.reload()
        
        print("after reload intrinsicContentSize", textCV.intrinsicContentSize.height, textCV.intrinsicContentSize.width)
        
        self.currentLinesAmount = CGFloat(textCV.actualNumberOfLines)
                
        print("textCV.actualNumberOfLines", textCV.actualNumberOfLines)
    }

    func setData(model: [DailyFoodReportModel], key: String) {
        
        guard let user = PreferencesService.user else { return }
        
        self.currentTime = key
        
        timeText.text = key
        
        updateUIBy(isFromMealSettings: isFromMealSettings(time: key, user: user), isEmpty: model.isEmpty)
        
        setTextCollectionView(with: model.map({ $0.food }))
        
        reloadConstraintValues(isEmpty: model.isEmpty)
    }
    
    private func isFromMealSettings(time: String, user: User) -> Bool {
        let b = getMealTimeString(by: user.date(of: user.meal.breakfast))
        let l = getMealTimeString(by: user.date(of: user.meal.lunch))
        let d = getMealTimeString(by: user.date(of: user.meal.dinner))
        
        return b == time || l == time || d == time
    }
    
    private func getDateFromCurrentCell() -> Date? {
        let selectedCalendarDate = PreferencesService.selectedCalendarDate
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"
        let dateString = dateFormatter.string(from: selectedCalendarDate)
        dateFormatter.dateFormat = Locale.is12HoursFormat() ? "MM-dd-yyyy hh:mm a" : "MM-dd-yyyy HH:mm"
        let finalStr = dateString + " \(currentTime)"
        return dateFormatter.date(from: finalStr)
    }
    
    private func pressedPlusBtnAction() {
        plusBtnTappedHandler?(getDateFromCurrentCell() ?? PreferencesService.selectedCalendarDate)
    }
    
    private func expandCell(_ button: UIButton) {
        isExpanded.toggle()
        
        expandBtn.setImage(UIImage(systemName: isExpanded ? "chevron.up" : "chevron.down", withConfiguration: UIImage.SymbolConfiguration(scale: .small))?.withRenderingMode(.alwaysTemplate), for: .normal)
        textCV.numberOfLines = isExpanded ? UInt(currentLinesAmount) : 2
        
        if isExpanded {
            textCV.frame = CGRect(x: textCVView.frame.minX,
                                  y: textCVView.frame.minY,
                                  width: textCVView.frame.width,
                                  height: currentLinesAmount * 24 + ((currentLinesAmount - 1) * 8) + 24)
        } else {
            textCV.frame = CGRect(x: textCVView.frame.minX,
                                  y: textCVView.frame.minY,
                                  width: textCVView.frame.width,
                                  height: Defaults.def2RawsSize)
        }
        textCV.reload()
        textCVViewHeight.constant = isExpanded ?
        currentLinesAmount * 24 + ((currentLinesAmount - 1) * 8) + 24
        :
        Defaults.def2RawsSize
        
        reloadTVHandler?()
    }
    
    private func drawDottedLine(start p0: CGPoint, end p1: CGPoint, view: UIView) {
        let shapeLayer = CAShapeLayer()
        shapeLayer.strokeColor = UIColor(red: 0.35, green: 0.73, blue: 1, alpha: 1).cgColor
        shapeLayer.lineWidth = 2
        shapeLayer.lineDashPattern = [4, 4] // 7 is the length of dash, 3 is length of the gap.

        let path = CGMutablePath()
        path.addLines(between: [p0, p1])
        shapeLayer.path = path
        self.tlView.layer.addSublayer(shapeLayer)
    }
    
    private func getFoodItemFromTag(by id: UInt) -> FoodAndDish? {
        tagsDict[id]
    }
    
    //MARK: - Actions
    @IBAction private func expandButtonPressed(_ sender: UIButton) {
        expandCell(sender)
    }
    
    @IBAction private func plusButtonPressed(_ sender: UIButton) {
        pressedPlusBtnAction()
    }
}

//MARK: - TTGTextTagCollectionViewDelegate
extension TimelineTableViewCellNew: TTGTextTagCollectionViewDelegate {
    func textTagCollectionView(_ textTagCollectionView: TTGTextTagCollectionView!, didTap tag: TTGTextTag!, at index: UInt) {
        let food = getFoodItemFromTag(by: tag.tagId)
        tagTappedHandler?(food, getDateFromCurrentCell() ?? PreferencesService.selectedCalendarDate)
    }
}
