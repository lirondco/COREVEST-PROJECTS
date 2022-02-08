import { LightningElement, api } from "lwc";
import init from "@salesforce/apex/ChecklistController.init";
import handleUpload from "@salesforce/apex/ChecklistController.handleUpload";
import deleteItem from "@salesforce/apex/ChecklistController.deleteItem";
import approveItems from "@salesforce/apex/ChecklistController.approveItems";
import getMilestoneList from "@salesforce/apex/ChecklistController.getMilestoneList";
export default class Checklist extends LightningElement {
  @api recordId = "0068B000002XlpAQAS";
  @api objectApiName;

  // milestones = [];
  currentMilestone;
  // selectedMilestone;
  checklist;

  activeSection = ["uploads"];

  milestones = [];

  connectedCallback() {
    this.getMilestones();
    this.init();
  }

  getMilestones() {
    getMilestoneList({ recordId: this.recordId })
      .then((milestones) => {
        this.milestones = milestones;
      })
      .catch((error) => {
        console.log(error);
      });
  }

  init() {
    //console.log("fire this");
    init({ recordId: this.recordId })
      .then((results) => {
        const checklist = JSON.parse(results);

        console.log(checklist);
        this.currentMilestone = checklist.milestones[0].name;
        // this.selectedMilestone
        // console.log(this.currentMilestone);
        this.checklist = checklist;
      })
      .catch((error) => {
        console.log("error");
      });
  }

  get sectionTypes() {
    const types = [];
    // if (this.checklist) {
    const sectionTypes = {};
    const currentMilestone = this.currentMilestone;
    let index;

    this.checklist.milestones.forEach((milestone, milestoneIndex) => {
      if (milestone.name === currentMilestone) {
        index = milestoneIndex;
      }
    });

    const milestone = this.checklist.milestones[index];
    // console.log(sections);
    milestone.sections.forEach((section, sectionIndex) => {
      if (!sectionTypes[section.sectionType]) {
        sectionTypes[section.sectionType] = [];
      }
      sectionTypes[section.sectionType].push(section);
    });

    console.log(sectionTypes);

    for (const [key, value] of Object.entries(sectionTypes)) {
      const type = { name: key, sections: value };

      types.push(type);
    }
    // this.checklist.milestones[index];
    // }

    return types;
  }

  // get milestones() {
  //   const milestones = [];

  //   // this.checklist.milestones.forEach
  //   // console.log(this.checklist.milestones);
  //   this.checklist.milestones.forEach((milestone) => {
  //     milestones.push(milestone.name);
  //   });
  //   // console.log(milestones);
  //   return milestones;
  // }

  handleMilestoneClick(event) {
    const milestone = event.target.getAttribute("data-milestone");

    console.log(milestone);

    this.currentMilestone = milestone;
  }

  approveAll(event) {
    const sectionId = event.target.getAttribute("data-id");
    const type = event.target.getAttribute("data-type");

    const itemIds = [];
    this.template
      .querySelectorAll(
        `[data-item="item"][data-id="${sectionId}"][data-type="${type}"]`
      )
      .forEach((input) => {
        if (input.checked) {
          itemIds.push(input.getAttribute("data-itemid"));
        }
      });

    console.log(itemIds);

    if (itemIds.length > 0) {
      approveItems({ itemIds })
        .then(() => {
          this.init();
        })
        .catch((error) => {
          console.log(error);
        });
    }
  }

  selectAll(event) {
    console.log(event);
    // console.log(event.target.getAttribute)
    const sectionId = event.target.getAttribute("data-id");
    const type = event.target.getAttribute("data-type");
    const checked = event.target.checked;
    console.log(sectionId);
    console.log(type);

    console.log(checked);

    console.log(
      this.template.querySelectorAll(
        `[data-item="item"][data-id="${sectionId}"][data-type="${type}"]`
      )
    );

    this.template
      .querySelectorAll(
        `[data-item="item"][data-id="${sectionId}"][data-type="${type}"]`
      )
      .forEach((input) => {
        input.checked = checked;
      });
  }

  handleUploadFinished(event) {
    console.log("upload finished");
    console.log(event.target.getAttribute("data-id"));
    const itemId = event.target.getAttribute("data-id");
    // const uploadedFiles = event.detail.files;
    console.log(event.detail.files);
    const contentVersionIds = [];
    event.detail.files.forEach((file) => {
      contentVersionIds.push(file.contentVersionId);
    });

    handleUpload({ itemId, contentVersionIds })
      .then((result) => {
        init({ recordId: this.recordId })
          .then((results) => {
            const checklist = JSON.parse(results);

            this.currentMilestone = checklist.milestones[0].name;
            // this.selectedMilestone
            // console.log(this.currentMilestone);
            this.checklist = checklist;
          })
          .catch((error) => {
            console.log("error");
          });
      })
      .catch((error) => {
        console.log(error);
        console.log("--error--");
      });
  }

  openDocumentModal(event) {
    const itemId = event.target.getAttribute("data-id");
    console.log(itemId);

    this.template.querySelector("c-checklist-documents").openModal(itemId);
  }

  menuItemSelect(event) {
    // console.log(event);

    const itemId = event.target.getAttribute("data-id");
    console.log(itemId);
    console.log(event.detail.value);

    const value = event.detail.value;

    if (value === "edit") {
      //
      this.template.querySelector("c-checklist-item-edit").open(itemId);
    } else if (value === "delete") {
      deleteItem({ itemId })
        .then(() => {
          this.init();
        })
        .catch((error) => {
          console.log("delete error");
          console.log(error);
        });
    }
  }

  newItem(event) {
    const sectionId = event.target.getAttribute("data-id");
    const itemType = event.target.getAttribute("data-type");
    console.log(sectionId);
    console.log(itemType);

    this.template
      .querySelector("c-checklist-item-new")
      .open(sectionId, itemType);
  }
}