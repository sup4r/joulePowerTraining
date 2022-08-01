//
//  WorkoutSummaryViewController.swift
//  Joule-Power-Training
//
//  Created by Drew Shayotovich on 4/24/22.
//

import UIKit
import Firebase
import SwiftUI
import Charts

class WorkoutSummaryViewController: UIViewController, UIScrollViewDelegate {
       
    // Variables from Previous Segue
    var currentWorkout: ScheduledWorkout = ScheduledWorkout(uniqueID: "default", athleteName: "default", athleteFirst: "default", athleteLast: "default", exercise: "default", setNumber: 0, targetLoad: 0, targetReps: 0, targetVelocity: 0, weekOfYear: 0, weekYear: 0, workoutCompleted: true)
    var completedReps: [CompletedRep] = []
    var partialCompletedReps: [PartialCompetedRep] = []
    var completedSet: CompletedSet?
    
    var slides: [RepSummarySlide] = []
    let imageArray: [UIImage] = [UIImage(named: K.feedbackImages.greenFilled)!, UIImage(named: K.feedbackImages.greenOpen)!, UIImage(named: K.feedbackImages.yellow)!, UIImage(named: K.feedbackImages.red)!, UIImage(named: K.feedbackImages.grey)!]
    
    @IBOutlet weak var athleteAndWorkoutInfoView: UIView!
    @IBOutlet weak var setAndVelocityView: UIView!
    @IBOutlet weak var setView: UIView!
    @IBOutlet weak var velocityView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    @IBOutlet weak var firstNameView: UIView!
    @IBOutlet weak var lastNameView: UIView!
    @IBOutlet weak var repSummaryLabelView: UIView!
    @IBOutlet weak var setFeedbackView: UIView!
    
    @IBOutlet weak var separatorView: UIView!
    
    @IBOutlet weak var headshotImage: UIImageView!
    @IBOutlet weak var headshotHeight: NSLayoutConstraint!
    @IBOutlet weak var headshotWidth: NSLayoutConstraint!
    @IBOutlet weak var nameAndSummaryHeight: NSLayoutConstraint!
    @IBOutlet var feedbackImages: [UIImageView]!
    
    //MARK: - Set Summary Variable Outlets
    @IBOutlet weak var setExerciseLabel: UILabel!
    @IBOutlet weak var setLoadLabel: UILabel!
    @IBOutlet weak var setVelocityTargetLabel: UILabel!
    @IBOutlet weak var setNumberLabel: UILabel!
    @IBOutlet weak var setRepsCompletedLabel: UILabel!
    @IBOutlet weak var firstNameLabel: UILabel!
    @IBOutlet weak var lastNameLabel: UILabel!
    @IBOutlet weak var averageVelocityLabel: UILabel!
    @IBOutlet weak var maxVelocityLabel: UILabel!
    @IBOutlet weak var averagePowerLabel: UILabel!
    @IBOutlet weak var maxPowerLabel: UILabel!
    @IBOutlet weak var averageTTPLabel: UILabel!
    @IBOutlet weak var maxTTPLabel: UILabel!
    
    // DEBUG Variables
    var reps: [Int] = [0, 1, 2, 3]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        analyzePartialReps(partialReps: partialCompletedReps)
        completedSet = CompletedSet(completedReps: completedReps)
        
        if completedReps.count == 0 {
            navigationController?.popViewController(animated: true)
            
//      To be used for debug
//        if reps.count == 0 {
//            navigationController?.popViewController(animated: true)
//
        } else {
            adjustLayout()
            layoutScrollView()
            updateSetData()
            fillInFeedbackImages(images: feedbackImages, completedReps: completedReps)
        }
    }
    
    func analyzePartialReps(partialReps: [PartialCompetedRep]) {
        for rep in partialReps {
            let completeRep = CompletedRep(timeArray: rep.timeArray, velocityArray: rep.velocityArray, load: currentWorkout.targetLoad, targetVelocity: currentWorkout.targetVelocity)
            completedReps.append(completeRep)
        }
    }
    
    @objc private func pageControlDidChange(_ sender: UIPageControl) {
        let currentPage = sender.currentPage
        scrollView.setContentOffset(CGPoint(x: CGFloat(currentPage) * view.frame.width, y: 0), animated: true)
    }
    
    func createSlides() -> [RepSummarySlide] {
        for index in 0 ..< completedReps.count {
            let slide = Bundle.main.loadNibNamed("RepSummarySlide", owner: self, options: nil)?.first as! RepSummarySlide
            
            setVelocityGraph(completedRep: completedReps[index], chartView: slide.velocityGraphView)
            setPowerGraph(completedRep: completedReps[index], chartView: slide.powerGraphView)
            
            slides.append(slide)
        }
        return slides
    }
    
    func setVelocityGraph(completedRep: CompletedRep, chartView: LineChartView) {
        var yValuesVelocity: [ChartDataEntry] = []
        
        for index in completedRep.beginRepIndex ... completedRep.endRepIndex {
            let entryPoint = ChartDataEntry(x: completedRep.normalizedTimeArray[index], y: completedRep.velocityArray[index])
            yValuesVelocity.append(entryPoint)
        }
        
        let dataVelocity = setData(yValues: yValuesVelocity, color: "Color1-2")
        chartView.data = dataVelocity
        
        formatLineGraph(chartView: chartView, color: "Color1-2")
    }
    
    func setPowerGraph(completedRep: CompletedRep, chartView: LineChartView) {
        var yValuesPower: [ChartDataEntry] = []
        
        for index in 0 ..< completedRep.accelerationTimeArray.count {
            let entryPoint = ChartDataEntry(x: completedRep.accelerationTimeArray[index], y: Double(completedRep.powerArray[index]))
            yValuesPower.append(entryPoint)
        }
        
        let dataPower = setData(yValues: yValuesPower, color: "Color5")
        chartView.data = dataPower
        
        formatLineGraph(chartView: chartView, color: "Color5")
    }
    
    func setData(yValues: [ChartDataEntry], color: String) -> LineChartData {
        let set1 = LineChartDataSet(entries: yValues, label: nil)
        set1.mode = .cubicBezier
        set1.drawCirclesEnabled = false
        set1.lineWidth = 2
        set1.setColor(UIColor(named: color) ?? .systemRed)
        set1.fill = Fill(CGColor: (UIColor(named: color) ?? .systemRed).cgColor)
        set1.fillAlpha = 0.5
        set1.drawFilledEnabled = true
        set1.drawHorizontalHighlightIndicatorEnabled = false
        set1.drawVerticalHighlightIndicatorEnabled = false
        
        let data = LineChartData(dataSet: set1)
        data.setDrawValues(false)
        
        return data
    }
    
    func formatLineGraph(chartView: LineChartView, color: String) {
        chartView.rightAxis.enabled = false
        chartView.legend.enabled = false
        let yAxis = chartView.leftAxis
        
        yAxis.labelFont = .boldSystemFont(ofSize: 10)
        yAxis.setLabelCount(6, force: false)
        yAxis.labelTextColor = UIColor(named: color) ?? .systemRed
        yAxis.axisLineColor = UIColor(named: color) ?? .systemRed
        yAxis.labelPosition = .outsideChart
        
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.labelFont = .boldSystemFont(ofSize: 10)
        chartView.xAxis.setLabelCount(6, force: false)
        chartView.xAxis.labelTextColor = UIColor(named: color) ?? .systemRed
        chartView.xAxis.axisLineColor = UIColor(named: color) ?? .systemRed
        
        chartView.backgroundColor = UIColor(named: "Color4-2") ?? .systemRed
        chartView.drawGridBackgroundEnabled = false
        chartView.animate(xAxisDuration: 1.5)
    }
    
    func fillInFeedbackImages(images: [UIImageView], completedReps: [CompletedRep]) {
        for index in 0 ..< completedReps.count {
            if completedReps[index].averageVelocity >= currentWorkout.targetVelocity {
                images[index].image = imageArray[0]
            } else if completedReps[index].averageVelocity >= (currentWorkout.targetVelocity - 5) {
                images[index].image = imageArray[2]
            } else if completedReps[index].averageVelocity < (currentWorkout.targetVelocity - 5) {
                images[index].image = imageArray[3]
            } else {
                images[index].image = imageArray[4]
            }
        }
    }
    
    func setUpScrollView(slides: [RepSummarySlide]) {
        scrollView.frame = CGRect(x: 0, y: scrollView.frame.minY, width: view.frame.width, height: scrollView.frame.height)
        scrollView.contentSize = CGSize(width: view.frame.width * CGFloat(slides.count), height: scrollView.frame.height)
        scrollView.isPagingEnabled = true
        
        for i in 0 ..< slides.count {
            slides[i].frame = CGRect(x: view.frame.width * CGFloat(i), y: 0, width: view.frame.width, height: scrollView.frame.height)
            scrollView.addSubview(slides[i])
        }
    }
    
    func adjustLayout() {
        headshotHeight.constant = view.bounds.height / 5.5
        headshotWidth.constant = view.bounds.height / 5.5
        nameAndSummaryHeight.constant = headshotWidth.constant / 6
        
        headshotImage.asCircle()
        
        for image in feedbackImages {
            image.asCircle()
        }
    }
    
    func layoutScrollView() {
        scrollView.delegate = self
        slides = createSlides()
        setUpScrollView(slides: slides)
        
        pageControl.numberOfPages = slides.count
        pageControl.currentPage = 0
        view.bringSubviewToFront(pageControl)
        pageControl.addTarget(self,
                              action: #selector(pageControlDidChange(_:)),
                              for: .valueChanged)
    }
    
    func updateSetData() {
        setExerciseLabel.text = currentWorkout.exercise
        setLoadLabel.text = "\(currentWorkout.targetLoad) lbs"
        let targetVelocityConversion = Double(currentWorkout.targetVelocity) / Double(100)
        setVelocityTargetLabel.text = String(format: "%.2f", targetVelocityConversion)
        setNumberLabel.text = String(currentWorkout.setNumber)
        setRepsCompletedLabel.text = String(currentWorkout.targetReps)
        firstNameLabel.text = currentWorkout.athleteFirst
        lastNameLabel.text = currentWorkout.athleteLast
        
        let averageVelocityConversion = Double(completedSet!.averageVelocity) / Double(100)
        averageVelocityLabel.text = String(format: "%.2f", averageVelocityConversion)
        let maxVelocityConversion = Double(completedSet!.maxVelocity) / Double(100)
        maxVelocityLabel.text = String(format: "%.2f", maxVelocityConversion)
        
        averagePowerLabel.text = String(completedSet!.averagePower)
        maxPowerLabel.text = String(completedSet!.maxPower)
        
        averageTTPLabel.text = String(format: "%.2f", completedSet!.averageTTP)
        maxTTPLabel.text = String(format: "%.2f", completedSet!.maxTTP)
    }
    
}

extension WorkoutSummaryViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        pageControl.currentPage = Int(floorf(Float(scrollView.contentOffset.x) / Float(scrollView.frame.width)))
    }
}
