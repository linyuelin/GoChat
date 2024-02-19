//
//  NewConversationViewController.swift
//  Messenger
//
//  Created by dreaMTank on 2024/01/31.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {
    
    public var completion: ((SearchResult) -> (Void))?
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private var users = [[String: String]]()
    
    private var results = [SearchResult]()
    
    private var hasFetched = false
    
    private let searchBar : UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "検索"
        return searchBar
    }()
    
    private let tableView: UITableView = {
       let table = UITableView()
        table.isHidden = true
        table.register(NewConversationCell.self, forCellReuseIdentifier: NewConversationCell.identifier)
        return  table
    }()
    
    
    private let noResultsLabel: UILabel = {
       let label = UILabel()
        label.isHidden = true
        label.text = "検索結果はありません"
        label.textAlignment = .center
        label.textColor = .green
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(noResultsLabel)
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        searchBar.delegate = self
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "キャンセル", style: .done, target: self, action: #selector(dismissSelf))
        
        
        //searchBarにフォーカスを与え、キーボード入力を受け入れられる状態にする
        searchBar.becomeFirstResponder()
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noResultsLabel.frame = CGRect(x: view.width/4, y: (view.height-200)/2, width: view.width/2, height: 200)
    }
    
    
    @objc private func dismissSelf(){
        dismiss(animated: true , completion: nil)
    }

  
}


extension NewConversationViewController: UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model =  results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationCell.identifier, for: indexPath) as! NewConversationCell
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        //会話を始める
        let targetUserData = results[indexPath.row]
        
        dismiss(animated: true , completion: { [weak self] in
            self?.completion?(targetUserData)
        })
        
       
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
    
}

extension NewConversationViewController: UISearchBarDelegate {
    
    //検索ボタンをクリックした際に呼ばれる
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        //text.replacingOccurrences(of: " ", with: "")メソッドを使用して空白を空文字列に置き換えます
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else{
            return
        }
        
        // 検索バーからフォーカスを外し、キーボードを閉じます
        searchBar.resignFirstResponder()
        
        // 新しい検索結果を取得する前に、古い検索結果をクリアします
        results.removeAll()
        
        //ローディングスピナーを表示する
        spinner.show(in: view)
        
        //searchUsers(query:) メソッドを呼び出し
        self.searchUsers(query: text)
    }
    
     func searchUsers(query: String) {
         
         // Firebaseの結果が含まれているか確認
         if hasFetched {
             // Firebaseの結果がある場合:
             filterUsers(with: query)
         }
         
         else {
             //Firebaseの結果が含まれていない場合: 取得してからフィルタリング
             DatabaseManager.shared.getAllUsers(completion: { [weak self] result in
                 switch result {
                 case .success(let usersCollection):
                     self?.hasFetched = true
                     self?.users = usersCollection
                     self?.filterUsers(with: query)
                 case .failure(let error):
                     print("ユーザー取得に失敗した: \(error)")
                 }
             })
         }
    }
    
    func filterUsers(with term: String) {
        //UIの更新: 結果の表示または非表示
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String , hasFetched else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
        self.spinner.dismiss()
        
        //filter（）メソッドでusersの要素をフィルタリングする
       let results : [SearchResult] = self.users.filter({
           
           guard let email = $0["email"]  ,email != safeEmail else {
               return false
           }
           //ユーザー名を小文字に変換して取得
            guard let name = $0["name"]?.lowercased() else {
                //ユーザー名が取得できない場合は
                return false
            }
           
           //比較
            return name.hasPrefix(term.lowercased())
       }).compactMap({
           
           guard let email = $0["email"] , 
                 let name = $0["name"] else {
                 return nil
           }
           
           return SearchResult(name: name, email: email)
       })
        
        self.results = results
        
         updateUI()
    }
    
    
    //画面更新
    func updateUI() {
        if results.isEmpty {
            self.noResultsLabel.isHidden = false
            self.tableView.isHidden = true
        }
        else {
            self.noResultsLabel.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
}

struct SearchResult {
    let name: String
    let email: String
}
