//
//  GoalsViewController.swift
//  goalpost
//
//  Created by Hüseyin Emre Sarıoğlu on 1.05.2024.
//

import UIKit
import CoreData

class GoalsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var goals: [Goal] = []
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isHidden = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(fetchGoals), name: NSNotification.Name("goalSaved"), object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchGoals()
    }

    @IBAction func addGoalBtnPressed(_ sender: UIButton) {
        guard let createGoalVC = storyboard?.instantiateViewController(withIdentifier: "CreateGoalViewController") as? CreateGoalViewController else {return}
        presentDetail(createGoalVC)
    }

}

extension GoalsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return goals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "goalCell") as? GoalCell else {return UITableViewCell()}
        
        let goal = goals[indexPath.row]
        
        cell.configureCell(goal: goal)
        cell.addButton.tag = indexPath.row
        cell.addButton.addTarget(self, action: #selector(increaseProgress(sender:)), for: .touchUpInside)
        return cell
    }
    
    @objc func increaseProgress(sender: UIButton) {
        let goal = goals[sender.tag]
        if goal.goalProgress < goal.goalCompletionValue {
            goal.goalProgress += 1
            saveContext()
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Silme işlemini gerçekleştir
            let deletedGoal = goals[indexPath.row]
            self.deleteGoal(deletedGoal) { (complete) in
                if complete {
                    dismiss(animated: true, completion: nil)
                }
            }
            goals.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    
}

extension GoalsViewController {
    func fetch(completion: (_ complete: Bool) -> ()) {
        guard let managedContext = appDelegate?.persistentContainer.viewContext else {return}
        
        let fetchRequest = NSFetchRequest<Goal>(entityName: "Goal")
        do {
            goals = try managedContext.fetch(fetchRequest)
            completion(true)
        } catch {
            debugPrint("Could not fetch: \(error.localizedDescription)")
            showAlert(title: "Error", message: "Failed to fetch goals. Please try again.")
            completion(false)
        }
    }
    
    @objc func fetchGoals() {
        self.fetch { (complete) in
            if complete {
                if goals.count >= 1 {
                    tableView.isHidden = false
                } else {
                    tableView.isHidden = true
                }
            }
        }
        tableView.reloadData()
    }
    
    func saveContext() {
        do {
            try appDelegate?.persistentContainer.viewContext.save()
        } catch {
            debugPrint("Could not save: \(error.localizedDescription)")
        }
    }
    
    func deleteGoal(_ goal: Goal, completion: (_ finished: Bool) -> ()) {
        guard let managedContext = appDelegate?.persistentContainer.viewContext else {return}
        managedContext.delete(goal)
        do {
            try managedContext.save()
            completion(true)
        } catch {
            debugPrint("Could not delete: \(error.localizedDescription)")
            showAlert(title: "Error", message: "Failed to delete goal. Please try again.")
            completion(false)
        }
    }

    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
}

