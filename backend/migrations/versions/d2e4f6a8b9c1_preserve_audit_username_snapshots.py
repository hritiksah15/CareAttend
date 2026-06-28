"""preserve audit username snapshots

Revision ID: d2e4f6a8b9c1
Revises: c1e8a4b9d720
Create Date: 2026-06-28 00:00:00.000000

"""
from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision = 'd2e4f6a8b9c1'
down_revision = 'c1e8a4b9d720'
branch_labels = None
depends_on = None


def upgrade():
    with op.batch_alter_table('audit_logs') as batch_op:
        batch_op.add_column(
            sa.Column('username_snapshot', sa.String(length=80), nullable=True)
        )
        batch_op.alter_column(
            'user_id', existing_type=sa.String(length=36), nullable=True
        )


def downgrade():
    # Rows detached from deleted users cannot satisfy the old NOT NULL
    # constraint, so remove only those rows when downgrading the schema.
    op.execute("DELETE FROM audit_logs WHERE user_id IS NULL")
    with op.batch_alter_table('audit_logs') as batch_op:
        batch_op.alter_column(
            'user_id', existing_type=sa.String(length=36), nullable=False
        )
        batch_op.drop_column('username_snapshot')
