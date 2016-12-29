ActiveAdmin.register Payola::Sale, as: "Sale" do
  menu label: "Sales", parent: "Plans"

  filter :created_at
end
