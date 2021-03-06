//
//  YIAddBillVc.m
//  XiaoJia
//
//  Created by efeng on 16/9/11.
//  Copyright © 2016年 buerguo. All rights reserved.
//

#import "YIAddBillVc.h"
#import "YIBillItemsCv.h"
#import "YITextField.h"


@interface YIAddBillVc () <
        YIBillItemsCvDelegate,
        FrequencyViewDelegate> {
			
			
    YITextField *tfName;
	YITextField *tfMoney;
    FrequencyView *viewFrequency;

    YIFrequency *curFrequency;
	RLMObject *curBillItem;
	float curMoney;
}

@property (nonatomic, weak) YIBillItemsCv *billItemsCv;

@end

@implementation YIAddBillVc

- (void)viewDidLoad {
    [super viewDidLoad];
	self.title = @"添加费用项";
    self.edgesForExtendedLayout = UIRectEdgeNone;

    UIBarButtonItem *addItem = [[UIBarButtonItem alloc] initWithTitle:@"搞定"
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(commitBillItemAction:)];
    self.navigationItem.rightBarButtonItem = addItem;


    [self loadUI];
}

// 搞定
- (void)commitBillItemAction:(UIBarButtonItem *)bbi {
	if (curBillItem == nil || curFrequency == nil || curMoney <= 0.f) {
		[TSMessage showNotificationWithTitle:@"请完善各项信息并保证费用大于0!" type:TSMessageNotificationTypeWarning];
		return;
	}
	
	if ([curBillItem isKindOfClass:[YIExpensesTag class]]) {
		YIExpenses *expenses = [[YIExpenses alloc] init];
		expenses.expensesTag = (YIExpensesTag *)curBillItem;
		expenses.frequency = curFrequency;
		expenses.money = curMoney;
		[[RLMRealm defaultRealm] beginWriteTransaction];
		[_phase.expensesList addObject:expenses];
		[[RLMRealm defaultRealm] commitWriteTransaction];
	} else {
		YIIncome *income = [[YIIncome alloc] init];
		income.incomeTag = (YIIncomeTag *)curBillItem;
		income.frequency = curFrequency;
		income.money = curMoney;
		[[RLMRealm defaultRealm] beginWriteTransaction];
		[_phase.incomeList addObject:income];
		[[RLMRealm defaultRealm] commitWriteTransaction];
	}
	
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)loadUI {
    [self.view setBackgroundColor:kAppColorWhite];

    NSArray *segmentItems = @[@" 支出 ", @" 收入 "];
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:segmentItems];
    // 添加监听
    [segmentedControl addTarget:self action:@selector(segmentedControlOnChanged:) forControlEvents:UIControlEventValueChanged];
    segmentedControl.selectedSegmentIndex = 0;
    self.navigationItem.titleView = segmentedControl;

    YIBillItemsCv *billItemsCv = [[YIBillItemsCv alloc] init];
    billItemsCv.delegate = self;
    RLMResults *results = [YIExpensesTag allObjects];
    billItemsCv.items = results;
    [self.view addSubview:billItemsCv];
    [billItemsCv mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(billItemsCv.superview);
        make.left.equalTo(billItemsCv.superview);
        make.width.equalTo(billItemsCv.superview);
        make.height.equalTo(@(mScreenWidth / 5 * 2 + 10));
    }];
	self.billItemsCv = billItemsCv;

    tfName = [[YITextField alloc] init];
    tfName.enabled = NO;
    tfName.backgroundColor = kAppColorWhite;
	tfName.textColor = kAppColorTextDeep;
	[tfName setFont:[UIFont boldSystemFontOfSize:20]];
    [self.view addSubview:tfName];
    [tfName mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(billItemsCv.mas_bottom).offset(1);
        make.left.equalTo(tfName.superview);
        make.height.equalTo(@44);
    }];
	
	tfMoney = [[YITextField alloc] init];
	tfMoney.backgroundColor = kAppColorWhite;
	tfMoney.placeholder = @"费用";
	tfMoney.textColor = [UIColor salmonColor];
	[tfMoney setFont:[UIFont boldSystemFontOfSize:20]];
	tfMoney.keyboardType = UIKeyboardTypeNumberPad;
	[tfMoney addTarget:self action:@selector(curMoneyChanged:) forControlEvents:UIControlEventEditingChanged];
	[self.view addSubview:tfMoney];
	[tfMoney mas_makeConstraints:^(MASConstraintMaker *make) {
		make.top.equalTo(billItemsCv.mas_bottom).offset(1);
		make.left.equalTo(tfName.mas_right);
		make.right.equalTo(tfMoney.superview);
		make.width.equalTo(tfName.mas_width);
		make.height.equalTo(@44);
	}];

    viewFrequency = [[FrequencyView alloc] init];
    viewFrequency.delegate = self;
    [self.view addSubview:viewFrequency];
    [viewFrequency mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(tfName.mas_bottom);
		make.left.equalTo(viewFrequency.superview);
		make.width.equalTo(viewFrequency.superview);
		make.height.equalTo(@(mScreenWidth / 6.0));
	}];
	[viewFrequency loadUI];
}

- (void)curMoneyChanged:(YITextField *)textfield {
	curMoney = [textfield.text floatValue];
}

#pragma mark - YIBillItemsCvDelegate

- (void)didSelectBillItem:(RLMObject *)item;
{
	[tfMoney becomeFirstResponder];
	
    if ([item isKindOfClass:[YIExpensesTag class]]) {
        YIExpensesTag *tag = (YIExpensesTag *)item;
        tfName.text = tag.name;
		curBillItem = tag;
    } else if ([item isKindOfClass:[YIIncomeTag class]]) {
        YIIncomeTag *tag = (YIIncomeTag *)item;
        tfName.text = tag.name;
		curBillItem = tag;
    }
}

#pragma mark - FrequencyViewDelegate

-(void)didSelectFrequencyItem:(YIFrequency *)frequency {
    curFrequency = frequency;
}

#pragma mark -

- (void)segmentedControlOnChanged:(UISegmentedControl *)segmentedControl {
    if (segmentedControl.selectedSegmentIndex == 0) {
        RLMResults *results = [YIExpensesTag allObjects];
        _billItemsCv.items = results;
		
    } else if (segmentedControl.selectedSegmentIndex == 1) {
        RLMResults *results = [YIIncomeTag allObjects];
        _billItemsCv.items = results;
    }
	
	// 重设默认值
	tfName.text = @"";
	curBillItem = nil;
	
	tfMoney.text = @"";
	curMoney = 0.f;
}

- (void)dealloc {
	_billItemsCv = nil;
}

@end

#pragma mark - CLASS FrequencyView

@interface FrequencyView () {
    UIButton *prefixBtn;
    UIButton *curBtn;

    RLMResults *frequencys;
}

@end

@implementation FrequencyView

- (instancetype)init {
    self = [super init];
    if (self) {
        frequencys = [YIFrequency allObjects];
    }

    return self;
}

- (void)loadUI {
    UIView *viewFrequency = [[UIView alloc] init];
    [self addSubview:viewFrequency];
    [viewFrequency mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(viewFrequency.superview);
    }];

    UIView *lastView;
    for (NSUInteger i = 0; i < frequencys.count; ++i) {
        YIFrequency *frequency = frequencys[i];
        UIButton *button = [[UIButton alloc] init];
        button.tag = 1000+i;
//		[button setBackgroundImage:[UIImage imageWithColor:kAppColorLightGray] forState:UIControlStateNormal];
        [button setBackgroundImage:[UIImage imageWithColor:kAppColorOrange] forState:UIControlStateHighlighted];
        [button setBackgroundImage:[UIImage imageWithColor:kAppColorOrange] forState:UIControlStateSelected];
        button.titleLabel.font = kAppMidFont;
        [button setTitle:frequency.name forState:UIControlStateNormal];
        [button setTitleColor:kAppColorOrange forState:UIControlStateNormal];
        [button setTitleColor:kAppColorWhite forState:UIControlStateHighlighted];
        [button setTitleColor:kAppColorWhite forState:UIControlStateSelected];
        [button addTarget:self action:@selector(frequencyBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [viewFrequency addSubview:button];
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(lastView ? lastView.mas_right : button.superview);
            make.top.equalTo(button.superview);
            if (lastView) {
                make.width.equalTo(lastView);
            }
            make.height.equalTo(button.mas_width);
            if (i == frequencys.count - 1 && lastView) {
                make.right.equalTo(button.superview);
            }
        }];
        lastView = button;
    }

    curBtn = [viewFrequency viewWithTag:1000+0];
	if (curBtn) {
		[self frequencyBtnAction:curBtn];
	}
}

- (void)frequencyBtnAction:(UIButton *)button {
    prefixBtn = curBtn;
    curBtn = button;

    prefixBtn.selected = NO;
    curBtn.selected = YES;

    if ([_delegate respondsToSelector:@selector(didSelectFrequencyItem:)]) {
        [_delegate didSelectFrequencyItem:frequencys[button.tag-1000]];
    }
}

@end


